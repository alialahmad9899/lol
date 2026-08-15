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

        MethodInfo isSalesPurchase = typeof(InvoiceRenderer).GetMethod(
            "IsSalesPurchase",
            BindingFlags.Public | BindingFlags.Static,
            null,
            new Type[] { typeof(object) },
            null);
        MethodInfo print = typeof(InvoiceRenderer).GetMethod(
            "Print",
            BindingFlags.Public | BindingFlags.Static,
            null,
            new Type[] { typeof(object) },
            null);
        if (isSalesPurchase == null) throw new Exception("InvoiceRenderer.IsSalesPurchase(object) not found");
        if (print == null) throw new Exception("InvoiceRenderer.Print(object) not found");

        var importedCheck = module.Import(isSalesPurchase);
        var importedPrint = module.Import(print);
        int patched = 0;

        foreach (MethodDef method in form.Methods)
        {
            string name = method.Name.ToString();
            if (name != "bt_print_Click") continue;
            if (method.Parameters.Count != 3)
                throw new Exception("Unexpected bt_print_Click parameter count: " + method.Parameters.Count);
            if (method.Body == null || method.Body.Instructions.Count == 0)
                throw new Exception("bt_print_Click has no body");

            Instruction originalFirst = method.Body.Instructions[0];
            method.Body.Instructions.Insert(0, Instruction.Create(OpCodes.Ldarg_0));
            method.Body.Instructions.Insert(1, Instruction.Create(OpCodes.Call, importedCheck));
            method.Body.Instructions.Insert(2, Instruction.Create(OpCodes.Brfalse, originalFirst));
            method.Body.Instructions.Insert(3, Instruction.Create(OpCodes.Ldarg_0));
            method.Body.Instructions.Insert(4, Instruction.Create(OpCodes.Call, importedPrint));
            method.Body.Instructions.Insert(5, Instruction.Create(OpCodes.Ret));
            patched++;
        }

        if (patched == 0) throw new Exception("bt_print_Click was not found");
        Directory.CreateDirectory(Path.Combine(root, "build"));
        module.Write(output);
        File.WriteAllText(Path.Combine(root, "build", "patch-diagnostic.txt"), "PatchedHandlers=" + patched + Environment.NewLine + "OriginalBodyPreserved=True" + Environment.NewLine + "ConditionalTypes=فاتورة مبيع|فاتورة شراء");
        Console.WriteLine("PATCHED=TRUE");
        Console.WriteLine("ORIGINAL_BODY_PRESERVED=TRUE");
        return 0;
    }
}
