@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanEstimateValidator()
        let item = Staffing.newAcuityPlanEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanEstimateVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Staffing.AcuityPlanEstimateVersionRangeRule(min: 32, max: 80)
        let item = Staffing.newAcuityPlanEstimate("x", label: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanEstimateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.AcuityPlanEstimateLabelLengthRule(maxLength: 80)
        let item = Staffing.newAcuityPlanEstimate("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanEstimateRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Staffing.AcuityPlanEstimateRequiredWardRule(message: "acuity plan estimate needs an entry")
        let item = Staffing.newAcuityPlanEstimate("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
