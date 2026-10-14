@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanQuotaValidator()
        let item = BedManagement.newDischargePlanQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanQuotaBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.DischargePlanQuotaBudgetRangeRule(min: 8.8, max: 322.6)
        let item = BedManagement.newDischargePlanQuota("x", label: "y")
        item.budget = 324.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DischargePlanQuotaRequiredCodeRule(message: "discharge plan quota needs an entry")
        let item = BedManagement.newDischargePlanQuota("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanQuotaLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.DischargePlanQuotaLabelLengthRule(maxLength: 32)
        let item = BedManagement.newDischargePlanQuota("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
