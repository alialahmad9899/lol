using System;
using System.Data;
using System.Globalization;
using System.Text;
using System.Web;

namespace InvoiceTemplate
{
    public static class InvoiceRenderer
    {
        public static string Render(
            DataTable details,
            DataRow settingRow,
            DataRow clientRow,
            double[] previousBalances,
            double[] currentBalances,
            string moneyText,
            string clientName,
            string invoiceType,
            string invoiceNumber,
            DateTime invoiceDate,
            double totalAmount,
            double paidAmount,
            double remainingAmount,
            double discountAmount,
            string amountInWords,
            string clientStatus,
            string notes,
            string currencyText)
        {
            StringBuilder h = new StringBuilder(8192);
            string brand = "تاج بلاس";
            string customer = Safe(clientName);
            string type = Safe(invoiceType);
            string number = Safe(invoiceNumber);
            string currency = Safe(currencyText);
            if (currency.Length == 0) currency = "ل.س";
            double balance = totalAmount - paidAmount;

            h.Append("<!DOCTYPE html><html dir='rtl'><head><meta charset='utf-8'><style>");
            h.Append("@page{size:auto;margin:0;}html,body{margin:0;padding:0;background:#fff;}body{font-family:Tahoma,Arial,sans-serif;color:#111;font-size:11px;width:100%;max-width:76mm;margin:0 auto;padding:2mm 2mm 3mm;box-sizing:border-box;}*{box-sizing:border-box}.center{text-align:center}.brand{font-size:23px;font-weight:bold;line-height:1.1;margin-top:1px}.crown{font-family:Arial;font-size:25px;line-height:1;margin-bottom:1px}.subtitle{font-size:9px;color:#555;margin-top:2px}.rule{border-top:1px dashed #222;margin:5px 0}.meta{width:100%;border-collapse:collapse;margin:3px 0 1px}.meta td{padding:2px 0;vertical-align:top}.meta .label{font-weight:bold;width:27%;color:#444}.items{width:100%;border-collapse:collapse;margin-top:4px}.items th{border-bottom:1px solid #111;padding:4px 2px;font-size:10px}.items td{padding:4px 2px;border-bottom:1px dotted #aaa;vertical-align:top}.name{text-align:right;width:43%}.num{text-align:center;white-space:nowrap}.money{text-align:left;white-space:nowrap}.totals{width:100%;border-collapse:collapse;margin-top:4px}.totals td{padding:3px 1px}.totals .label{font-weight:bold;color:#444}.grand{font-size:14px;font-weight:bold;border-top:1px solid #111;border-bottom:1px double #111;padding:5px 0 !important}.note{font-size:9px;color:#444;line-height:1.5}.footer{margin-top:7px;padding-top:5px;border-top:1px dashed #222;text-align:center;font-size:10px}.thanks{font-size:12px;font-weight:bold;margin-top:3px}.muted{color:#666;font-size:9px}");
            h.Append("</style></head><body>");
            h.Append("<div class='center crown'>♛</div>");
            h.Append("<div class='center brand'>").Append(brand).Append("</div>");
            h.Append("<div class='center subtitle'>فاتورة ").Append(type).Append("</div>");
            h.Append("<div class='rule'></div>");

            h.Append("<table class='meta'>");
            Meta(h, "رقم الفاتورة", number);
            Meta(h, "التاريخ", invoiceDate.ToString("yyyy/MM/dd HH:mm", CultureInfo.InvariantCulture));
            if (customer.Length > 0) Meta(h, "العميل", customer);
            if (!String.IsNullOrEmpty(clientStatus)) Meta(h, "الحالة", Safe(clientStatus));
            h.Append("</table>");

            h.Append("<table class='items'><thead><tr><th class='name'>الصنف</th><th class='num'>الكمية</th><th class='money'>السعر</th><th class='money'>الإجمالي</th></tr></thead><tbody>");
            if (details != null)
            {
                foreach (DataRow r in details.Rows)
                {
                    string name = Safe(Get(r, "Name_elemnet"));
                    if (name.Length == 0) name = Safe(Get(r, "Name"));
                    double qty = Num(Get(r, "Quantity"));
                    double price = Num(Get(r, "Price"));
                    double line = Num(Get(r, "Prices_1"));
                    if (line == 0) line = Num(Get(r, "Prices_2"));
                    if (line == 0) line = (qty * price) - Num(Get(r, "Discount"));
                    h.Append("<tr><td class='name'>").Append(name).Append("</td><td class='num'>").Append(qty.ToString("0.##", CultureInfo.InvariantCulture)).Append("</td><td class='money'>").Append(price.ToString("0.##", CultureInfo.InvariantCulture)).Append("</td><td class='money'>").Append(line.ToString("0.##", CultureInfo.InvariantCulture)).Append("</td></tr>");
                }
            }
            h.Append("</tbody></table>");

            h.Append("<table class='totals'>");
            if (discountAmount != 0) Row(h, "الحسم", Money(discountAmount, currency), false);
            Row(h, "الإجمالي", Money(totalAmount, currency), true);
            if (paidAmount != 0) Row(h, "المدفوع", Money(paidAmount, currency), false);
            if (Math.Abs(balance) > 0.0001) Row(h, "المتبقي", Money(balance, currency), false);
            h.Append("</table>");

            if (!String.IsNullOrEmpty(amountInWords))
            {
                h.Append("<div class='note'><strong>المبلغ كتابةً:</strong> ").Append(Safe(amountInWords)).Append("</div>");
            }
            if (!String.IsNullOrEmpty(notes))
            {
                h.Append("<div class='note'><strong>ملاحظات:</strong> ").Append(Safe(notes)).Append("</div>");
            }
            h.Append("<div class='footer'><div class='thanks'>سررنا بزيارتكم، طاب يومكم 🌷</div><div class='muted'>نشكركم لثقتكم بنا</div></div>");
            h.Append("</body></html>");
            return h.ToString();
        }

        private static void Meta(StringBuilder h, string label, string value)
        {
            h.Append("<tr><td class='label'>").Append(label).Append("</td><td>").Append(value).Append("</td></tr>");
        }

        private static void Row(StringBuilder h, string label, string value, bool grand)
        {
            h.Append("<tr><td class='label ").Append(grand ? "grand" : "").Append("'>").Append(label).Append("</td><td class='money ").Append(grand ? "grand" : "").Append("'>").Append(value).Append("</td></tr>");
        }

        private static string Get(DataRow r, string col)
        {
            if (r == null || r.Table == null || !r.Table.Columns.Contains(col) || r[col] == DBNull.Value) return "";
            return Convert.ToString(r[col], CultureInfo.CurrentCulture);
        }

        private static double Num(string s)
        {
            double x;
            if (Double.TryParse(s, NumberStyles.Any, CultureInfo.CurrentCulture, out x)) return x;
            if (Double.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out x)) return x;
            return 0;
        }

        private static string Money(double v, string currency)
        {
            return v.ToString("0.##", CultureInfo.InvariantCulture) + " " + Safe(currency);
        }

        private static string Safe(string s)
        {
            if (s == null) return "";
            return HttpUtility.HtmlEncode(s);
        }
    }
}
