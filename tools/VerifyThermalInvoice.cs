using System;
using System.IO;
using dnlib.DotNet;

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
        if (print.Body == null || print.Body.Instructions.Count != 3)
            throw new Exception("bt_print_Click does not contain the expected adapter call");

        Console.WriteLine("StoreRuntime=" + module.RuntimeVersion);
        Console.WriteLine("PrintInstructions=" + print.Body.Instructions.Count);
        Console.WriteLine("VERIFIED=TRUE");
        return 0;
    }
}
