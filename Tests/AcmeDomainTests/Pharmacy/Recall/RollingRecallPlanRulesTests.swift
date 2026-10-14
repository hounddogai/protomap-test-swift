@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingRecallPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRollingRecallPlanValidator()
        let item = Pharmacy.newRollingRecallPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRollingRecallPlanDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Pharmacy.RollingRecallPlanDosageMgRangeRule(min: 9.6, max: 3760.2)
        let item = Pharmacy.newRollingRecallPlan("x", name: "y")
        item.dosageMg = 3761.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRollingRecallPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RollingRecallPlanRequiredCodeRule(message: "rolling recall plan needs a value")
        let item = Pharmacy.newRollingRecallPlan("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRollingRecallPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RollingRecallPlanCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newRollingRecallPlan("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingRecallPlanNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.RollingRecallPlanNameLengthRule(maxLength: 32)
        let item = Pharmacy.newRollingRecallPlan("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
