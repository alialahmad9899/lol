using System;
using System.IO;
using System.Reflection;
using dnlib.DotNet;
using dnlib.DotNet.Emit;
using InvoiceTemplate;

class PatchThermalInvoice
{
    static int Main()
    {
        string root = Directory.GetParent(Environment.CurrentDirectory).FullName;
        string input = Path.Combine(root, "Store.exe");
        string output = Path.Combine(root, "build", "Store_THERMAL.exe");
        var module = ModuleDefMD.Load(input);

        TypeDef form = null;
        foreach (TypeDef t in module.Types)
            if (t.FullName == "Store.Frm_Bill") { form = t; break; }
        if (form == null) throw new Exception("Store.Frm_Bill not found");

        MethodInfo print = typeof(InvoiceRenderer).GetMethod(
            "Print",
            BindingFlags.Public | BindingFlags.Static,
            null,
            new Type[] { typeof(object) },
            null);
        if (print == null) throw new Exception("InvoiceRenderer.Print(object) not found");

        var imported = module.Import(print);
        int patched = 0;
        foreach (MethodDef method in form.Methods)
        {
            string name = method.Name.ToString();
            if (name != "bt_print_Click") continue;
            if (method.Parameters.Count != 3)
                throw new Exception("Unexpected bt_print_Click parameter count: " + method.Parameters.Count);

            var body = new CilBody();
            body.Instructions.Add(Instruction.Create(OpCodes.Ldarg_0));
            body.Instructions.Add(Instruction.Create(OpCodes.Call, imported));
            body.Instructions.Add(Instruction.Create(OpCodes.Ret));
            method.Body = body;
            patched++;
        }

        if (patched == 0) throw new Exception("bt_print_Click was not found");
        Directory.CreateDirectory(Path.Combine(root, "build"));
        module.Write(output);
        File.WriteAllText(Path.Combine(root, "build", "patch-diagnostic.txt"), "PatchedHandlers=" + patched);
        Console.WriteLine("PATCHED=TRUE");
        return 0;
    }
}
