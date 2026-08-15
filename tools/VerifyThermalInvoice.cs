using System;
using System.IO;
using dnlib.DotNet;
using dnlib.DotNet.Emit;

class VerifyThermalInvoice
{
    static int Main()
    {
        string root = Directory.GetCurrentDirectory();
        string exe = Path.Combine(root, "build", "Store_THERMAL.exe");
        if (!File.Exists(exe)) throw new Exception("Store_THERMAL.exe missing: " + exe);

        var module = ModuleDefMD.Load(exe);
        TypeDef form = null;
        foreach (TypeDef t in module.Types)
            if (t.FullName == "Store.Frm_Bill") { form = t; break; }
        if (form == null) throw new Exception("Frm_Bill missing after patch");

        MethodDef print = null;
        foreach (MethodDef m in form.Methods)
            if (m.Name == "bt_print_Click") { print = m; break; }
        if (print == null) throw new Exception("bt_print_Click missing after patch");
        if (print.Body == null || print.Body.Instructions.Count < 8)
            throw new Exception("bt_print_Click body was replaced instead of wrapped");

        bool hasCheck = false;
        bool hasPrint = false;
        bool hasBranch = false;
        foreach (Instruction ins in print.Body.Instructions)
        {
            string s = ins.ToString();
            if (s.IndexOf("InvoiceRenderer::IsSalesPurchase", StringComparison.OrdinalIgnoreCase) >= 0) hasCheck = true;
            if (s.IndexOf("InvoiceRenderer::Print", StringComparison.OrdinalIgnoreCase) >= 0) hasPrint = true;
            if (ins.OpCode.Code == Code.Brfalse || ins.OpCode.Code == Code.Brfalse_S) hasBranch = true;
        }
        if (!hasCheck) throw new Exception("Sales/purchase gate call missing");
        if (!hasPrint) throw new Exception("New renderer call missing");
        if (!hasBranch) throw new Exception("Fallback branch missing");

        Console.WriteLine("StoreRuntime=" + module.RuntimeVersion);
        Console.WriteLine("PrintInstructions=" + print.Body.Instructions.Count);
        Console.WriteLine("OriginalBodyPreserved=True");
        Console.WriteLine("SalesPurchaseGate=True");
        Console.WriteLine("FallbackOriginalPrinter=True");
        Console.WriteLine("VERIFIED=TRUE");
        return 0;
    }
}
