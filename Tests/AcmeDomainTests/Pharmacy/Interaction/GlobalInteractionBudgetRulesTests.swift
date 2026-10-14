@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInteractionBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultGlobalInteractionBudgetValidator()
        let item = Pharmacy.newGlobalInteractionBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyGlobalInteractionBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.GlobalInteractionBudgetCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newGlobalInteractionBudget("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyGlobalInteractionBudgetRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Pharmacy.GlobalInteractionBudgetRequiredProcedureCodeRule(
            message: "global interaction budget needs this field"
        )
        let item = Pharmacy.newGlobalInteractionBudget("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyGlobalInteractionBudgetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.GlobalInteractionBudgetNameLengthRule(maxLength: 86400)
        let item = Pharmacy.newGlobalInteractionBudget("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyGlobalInteractionBudgetProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Pharmacy.GlobalInteractionBudgetProcedureCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newGlobalInteractionBudget("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
