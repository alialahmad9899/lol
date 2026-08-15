using System;
using System.Data;
using System.Globalization;
using System.Reflection;
using System.Text;
using System.Web;
using System.Windows.Forms;

namespace InvoiceTemplate
{
    public static class InvoiceRenderer
    {
        public static bool IsSalesPurchase(object frmBill)
        {
            if (frmBill == null) return false;
            string type = GetControlText(frmBill, "cb_Type_Bill");
            return type == "فاتورة مبيع" || type == "فاتورة شراء";
        }

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
            StringBuilder h = new StringBuilder(16384);

            string company = "تاج بلاست";
            string phone = Get(clientRow, "Mobile");
            if (phone.Length == 0) phone = Get(clientRow, "Phone");
            string address = Get(clientRow, "address");
            string companyPhone = Get(settingRow, "Mobile");
            if (companyPhone.Length == 0) companyPhone = Get(settingRow, "Phone");
            string companyAddress = Get(settingRow, "Address");
            string store = Get(settingRow, "Store");
            if (String.IsNullOrEmpty(store)) store = "";
            string currency = Safe(currencyText);
            if (currency.Length == 0) currency = "ل.س";

            string type = Safe(invoiceType);
            string number = Safe(invoiceNumber);
            string customer = Safe(clientName);
            string status = Safe(clientStatus);
            string memo = Safe(notes);
            string words = Safe(amountInWords);

            h.Append("<!DOCTYPE html><html dir='rtl'><head><meta charset='utf-8'><style>");
            h.Append("@page{size:auto;margin:0;}html,body{margin:0;padding:0;background:#fff;}body{font-family:Tahoma,Arial,sans-serif;color:#111;font-size:10px;width:76mm;max-width:76mm;margin:0 auto;padding:2mm 2mm 3mm;box-sizing:border-box;}*{box-sizing:border-box}.top{text-align:center;border:1px solid #111;border-radius:7px;padding:6px 5px 5px;margin-bottom:5px}.logo{width:34px;height:34px;margin:0 auto 3px;display:block}.brand{font-size:20px;font-weight:bold;line-height:1.05}.sub{font-size:10px;margin-top:3px;font-weight:bold}.meta-card,.items-card,.sum-card,.status-card,.footer-card{border:1px solid #111;border-radius:7px;margin-top:5px;padding:5px}.meta{width:100%;border-collapse:collapse}.meta td{padding:2px 1px;vertical-align:top}.meta .label{font-weight:bold;width:28%;}.items{width:100%;border-collapse:separate;border-spacing:0;overflow:hidden}.items th{background:#f4f4f4;border-bottom:1px solid #111;padding:4px 2px;font-size:9px}.items td{padding:4px 2px;border-bottom:1px dotted #aaa;vertical-align:top}.items tr:last-child td{border-bottom:0}.num{text-align:center;white-space:nowrap}.money{text-align:left;white-space:nowrap}.name{text-align:right}.item-note{font-size:8px;color:#666;line-height:1.3;margin-top:2px}.summary{width:100%;border-collapse:collapse}.summary td{padding:3px 1px}.summary .label{font-weight:bold}.grand{font-size:13px;font-weight:bold;border-top:1px solid #111;border-bottom:1px solid #111;padding:5px 1px!important}.small{font-size:8.5px;line-height:1.5}.balance-grid{width:100%;border-collapse:separate;border-spacing:3px}.balance-box{border:1px solid #111;border-radius:5px;text-align:center;padding:3px}.balance-label{font-size:8px;color:#555}.balance-value{font-weight:bold;margin-top:2px}.footer-card{text-align:center}.thanks{font-size:11px;font-weight:bold}.trust{font-size:8.5px;margin-top:3px}.line{border-top:1px dashed #111;margin:5px 0}.muted{color:#666}");
            h.Append("</style></head><body>");

            h.Append("<div class='top'>");
            h.Append("<svg class='logo' viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'><circle cx='50' cy='50' r='45' fill='none' stroke='#111' stroke-width='5'/><path d='M23 38 L34 25 L42 39 L50 21 L58 39 L66 25 L77 38 L72 62 C65 69 35 69 28 62 Z' fill='none' stroke='#111' stroke-width='5' stroke-linejoin='round'/><circle cx='50' cy='77' r='3' fill='#111'/></svg>");
            h.Append("<div class='brand'>").Append(company).Append("</div>");
            h.Append("<div class='sub'>").Append(type.Length == 0 ? "فاتورة" : "فاتورة " + type).Append("</div>");
            if (companyPhone.Length > 0 || companyAddress.Length > 0)
            {
                h.Append("<div class='small muted'>");
                if (companyPhone.Length > 0) h.Append("هاتف: ").Append(Safe(companyPhone));
                if (companyPhone.Length > 0 && companyAddress.Length > 0) h.Append(" | ");
                if (companyAddress.Length > 0) h.Append(Safe(companyAddress));
                h.Append("</div>");
            }
            h.Append("</div>");

            h.Append("<div class='meta-card'><table class='meta'>");
            Meta(h, "رقم الفاتورة", number);
            Meta(h, "التاريخ", invoiceDate.ToString("yyyy/MM/dd HH:mm", CultureInfo.InvariantCulture));
            if (customer.Length > 0) Meta(h, "العميل", customer);
            if (phone.Length > 0) Meta(h, "الهاتف", Safe(phone));
            if (address.Length > 0) Meta(h, "العنوان", Safe(address));
            if (store.Length > 0) Meta(h, "المستودع", Safe(store));
            h.Append("</table></div>");

            h.Append("<div class='items-card'><table class='items'><thead><tr><th class='num'>#</th><th class='name'>المادة</th><th class='num'>الوحدة</th><th class='num'>الكمية</th><th class='money'>السعر</th><th class='money'>الحسم</th><th class='money'>الإجمالي</th></tr></thead><tbody>");
            int index = 0;
            if (details != null)
            {
                foreach (DataRow row in details.Rows)
                {
                    string name = Get(row, "Name_elemnet");
                    if (name.Length == 0) continue;
                    index++;
                    double qty = GetDouble(row, "Quantity", GetDouble(row, "Q", 0d));
                    double price = GetDouble(row, "Price", GetDouble(row, "P1", 0d));
                    double gross = GetDouble(row, "Prices", GetDouble(row, "P2", qty * price));
                    double discount = GetDouble(row, "Discount", GetDouble(row, "P4", 0d));
                    double pct = GetDouble(row, "Percent_Discount", GetDouble(row, "P_Discount", 0d));
                    double net = GetDouble(row, "Prices_2", GetDouble(row, "Prices_1", gross - discount));
                    if (Math.Abs(net) < 0.0000001 && Math.Abs(gross) > 0.0000001)
                        net = gross - discount - gross * pct * 0.01d;
                    string unit = Get(row, "Name_Unit");
                    string itemNote = Get(row, "Notes_Details");
                    if (itemNote.Length == 0) itemNote = Get(row, "Notes");

                    h.Append("<tr><td class='num'>").Append(index.ToString(CultureInfo.CurrentCulture)).Append("</td><td class='name'><div>").Append(Safe(name)).Append("</div>");
                    if (itemNote.Length > 0) h.Append("<div class='item-note'>").Append(Safe(itemNote)).Append("</div>");
                    h.Append("</td><td class='num'>").Append(Safe(unit)).Append("</td><td class='num'>").Append(Math.Abs(qty).ToString("N2", CultureInfo.CurrentCulture)).Append("</td><td class='money'>").Append(price.ToString("N2", CultureInfo.CurrentCulture)).Append("</td><td class='money'>").Append(discount.ToString("N2", CultureInfo.CurrentCulture)).Append("</td><td class='money'>").Append(net.ToString("N2", CultureInfo.CurrentCulture)).Append("</td></tr>");
                }
            }
            if (index == 0)
                h.Append("<tr><td colspan='7' class='num muted'>لا توجد مواد</td></tr>");
            h.Append("</tbody></table></div>");

            h.Append("<div class='sum-card'><table class='summary'>");
            if (discountAmount != 0) Row(h, "الحسم", Money(discountAmount, currency), false);
            Row(h, "الإجمالي", Money(totalAmount, currency), true);
            if (paidAmount != 0) Row(h, "المدفوع", Money(paidAmount, currency), false);
            if (Math.Abs(remainingAmount) > 0.0001) Row(h, "المتبقي", Money(remainingAmount, currency), false);
            h.Append("</table>");
            if (words.Length > 0)
                h.Append("<div class='small'><strong>المبلغ كتابةً:</strong> ").Append(words).Append("</div>");
            h.Append("</div>");

            if (previousBalances != null || currentBalances != null || status.Length > 0 || memo.Length > 0)
            {
                h.Append("<div class='status-card'>");
                if (status.Length > 0) h.Append("<div class='small'><strong>الحالة المالية:</strong> ").Append(status).Append("</div>");
                if ((previousBalances != null && previousBalances.Length >= 2) || (currentBalances != null && currentBalances.Length >= 2))
                {
                    h.Append("<table class='balance-grid'><tr>");
                    if (previousBalances != null && previousBalances.Length >= 2)
                        h.Append("<td class='balance-box'><div class='balance-label'>الرصيد السابق</div><div class='balance-value'>").Append(previousBalances[0].ToString("N2", CultureInfo.CurrentCulture)).Append(" / ").Append(previousBalances[1].ToString("N2", CultureInfo.CurrentCulture)).Append("</div></td>");
                    if (currentBalances != null && currentBalances.Length >= 2)
                        h.Append("<td class='balance-box'><div class='balance-label'>الرصيد الحالي</div><div class='balance-value'>").Append(currentBalances[0].ToString("N2", CultureInfo.CurrentCulture)).Append(" / ").Append(currentBalances[1].ToString("N2", CultureInfo.CurrentCulture)).Append("</div></td>");
                    h.Append("</tr></table>");
                }
                if (memo.Length > 0) h.Append("<div class='small'><strong>ملاحظات:</strong> ").Append(memo).Append("</div>");
                h.Append("</div>");
            }

            h.Append("<div class='footer-card'><div class='line'></div><div class='thanks'>سررنا بزيارتكم، طاب يومكم 🌷</div><div class='trust'>نشكركم لثقتكم بنا</div></div>");
            h.Append("</body></html>");
            return h.ToString();
        }

        public static void Print(object frmBill)
        {
            if (frmBill == null) throw new ArgumentNullException("frmBill");
            if (!IsSalesPurchase(frmBill)) throw new InvalidOperationException("New invoice template is restricted to sales/purchase invoices.");

            DataTable details = GetField<DataTable>(frmBill, "row_details_bill");
            DataRow settings = InvokeDataRowMethod(frmBill, "Get_Setting", 1);
            string type = GetControlText(frmBill, "cb_Type_Bill");
            string number = GetControlText(frmBill, "txt_ID_Pay");
            string customer = GetControlText(frmBill, "cb_contacts");
            string currency = GetControlText(frmBill, "cb_Type_Money");
            DateTime date = GetControlDate(frmBill, "Date_Bill", DateTime.Now);
            double total = GetControlDouble(frmBill, "txt_Sum");
            double paid = GetControlDouble(frmBill, "txt_Sum5");
            double remaining = GetControlDouble(frmBill, "txt_Acazion");
            double discount = GetFieldDouble(frmBill, "Sum_Discount");
            string status = GetControlText(frmBill, "label15");
            string notes = GetControlText(frmBill, "txt_note");
            string words = InvokeNumToStr(frmBill, total);

            string html = Render(details, settings, null, null, null, "", customer, type, number, date,
                total, paid, remaining, discount, words, status, notes, currency);

            Form host = new Form();
            host.Text = type + " - " + number;
            host.StartPosition = FormStartPosition.CenterScreen;
            host.ShowInTaskbar = false;
            host.FormBorderStyle = FormBorderStyle.None;
            host.Opacity = 0.01;
            host.Width = 900;
            host.Height = 700;
            WebBrowser browser = new WebBrowser();
            browser.Dock = DockStyle.Fill;
            browser.ScriptErrorsSuppressed = true;
            host.Controls.Add(browser);
            bool printed = false;
            browser.DocumentCompleted += delegate(object sender, WebBrowserDocumentCompletedEventArgs e)
            {
                if (printed || browser.Document == null) return;
                if (e.Url != null && browser.Url != null && e.Url != browser.Url) return;
                printed = true;
                browser.Print();
                host.BeginInvoke(new MethodInvoker(delegate { host.Close(); }));
            };
            host.FormClosed += delegate { browser.Dispose(); host.Dispose(); };
            host.Show();
            browser.DocumentText = html;
        }

        private static string InvokeNumToStr(object o, double value)
        {
            try
            {
                FieldInfo f = o.GetType().GetField("m", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                object helper = f == null ? null : f.GetValue(o);
                if (helper != null)
                {
                    MethodInfo mi = helper.GetType().GetMethod("NumToStr", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic, null, new Type[] { typeof(double) }, null);
                    if (mi != null)
                    {
                        object v = mi.Invoke(helper, new object[] { value });
                        if (v != null) return Convert.ToString(v, CultureInfo.CurrentCulture);
                    }
                }
            }
            catch { }
            return value.ToString("N2", CultureInfo.CurrentCulture);
        }

        private static DataRow InvokeDataRowMethod(object o, string name, int arg)
        {
            try
            {
                MethodInfo mi = o.GetType().GetMethod(name, BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public, null, new Type[] { typeof(int) }, null);
                if (mi != null) return mi.Invoke(o, new object[] { arg }) as DataRow;
            }
            catch { }
            return null;
        }

        private static T GetField<T>(object o, string name) where T : class
        {
            FieldInfo f = o.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
            return f == null ? null : f.GetValue(o) as T;
        }

        private static double GetFieldDouble(object o, string name)
        {
            FieldInfo f = o.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
            if (f == null) return 0d;
            object v = f.GetValue(o);
            if (v == null) return 0d;
            double x;
            if (Double.TryParse(Convert.ToString(v, CultureInfo.CurrentCulture), NumberStyles.Any, CultureInfo.CurrentCulture, out x)) return x;
            if (Double.TryParse(Convert.ToString(v, CultureInfo.InvariantCulture), NumberStyles.Any, CultureInfo.InvariantCulture, out x)) return x;
            return 0d;
        }

        private static Control GetControl(object o, string name)
        {
            FieldInfo f = o.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
            return f == null ? null : f.GetValue(o) as Control;
        }

        private static string GetControlText(object o, string name)
        {
            Control c = GetControl(o, name);
            return c == null ? "" : Convert.ToString(c.Text, CultureInfo.CurrentCulture);
        }

        private static double GetControlDouble(object o, string name)
        {
            double x;
            string s = GetControlText(o, name);
            if (Double.TryParse(s, NumberStyles.Any, CultureInfo.CurrentCulture, out x)) return x;
            if (Double.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out x)) return x;
            return 0d;
        }

        private static DateTime GetControlDate(object o, string name, DateTime fallback)
        {
            FieldInfo f = o.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
            object v = f == null ? null : f.GetValue(o);
            DateTimePicker picker = v as DateTimePicker;
            return picker == null ? fallback : picker.Value;
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

        private static double GetDouble(DataRow r, string col, double fallback)
        {
            string s = Get(r, col);
            double x;
            if (Double.TryParse(s, NumberStyles.Any, CultureInfo.CurrentCulture, out x)) return x;
            if (Double.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out x)) return x;
            return fallback;
        }

        private static string Money(double v, string currency)
        {
            return v.ToString("N2", CultureInfo.CurrentCulture) + " " + Safe(currency);
        }

        private static string Safe(string s)
        {
            if (s == null) return "";
            return HttpUtility.HtmlEncode(s);
        }
    }
}
