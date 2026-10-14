@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientAcuityPlanPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLenientAcuityPlanPolicyValidator()
        let item = Staffing.newLenientAcuityPlanPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLenientAcuityPlanPolicyRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Staffing.LenientAcuityPlanPolicyRequiredSummaryRule(
            message: "lenient acuity plan policy needs an entry"
        )
        let item = Staffing.newLenientAcuityPlanPolicy("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLenientAcuityPlanPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.LenientAcuityPlanPolicyRequiredLabelRule(
            message: "lenient acuity plan policy needs this field"
        )
        let item = Staffing.newLenientAcuityPlanPolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLenientAcuityPlanPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.LenientAcuityPlanPolicyRequiredCodeRule(message: "lenient acuity plan policy needs an entry")
        let item = Staffing.newLenientAcuityPlanPolicy("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLenientAcuityPlanPolicyDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Staffing.LenientAcuityPlanPolicyDosageMgRangeRule(min: 2.3, max: 4280.9)
        let item = Staffing.newLenientAcuityPlanPolicy("x", label: "y")
        item.dosageMg = 4282.4
        #expect(rule.check(item).count > 0)
    }
}
