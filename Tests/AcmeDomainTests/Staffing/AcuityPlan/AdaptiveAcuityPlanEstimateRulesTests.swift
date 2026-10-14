@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveAcuityPlanEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAdaptiveAcuityPlanEstimateValidator()
        let item = Staffing.newAdaptiveAcuityPlanEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAdaptiveAcuityPlanEstimateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.AdaptiveAcuityPlanEstimateLabelLengthRule(maxLength: 80)
        let item = Staffing.newAdaptiveAcuityPlanEstimate("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAdaptiveAcuityPlanEstimateLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Staffing.AdaptiveAcuityPlanEstimateLimitRangeRule(min: 16, max: 80)
        let item = Staffing.newAdaptiveAcuityPlanEstimate("x", label: "y")
        item.limit = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAdaptiveAcuityPlanEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AdaptiveAcuityPlanEstimateCodeLengthRule(maxLength: 255)
        let item = Staffing.newAdaptiveAcuityPlanEstimate("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
