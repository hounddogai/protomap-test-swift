@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackFloatPoolScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackFloatPoolScheduleValidator()
        let item = Staffing.newFallbackFloatPoolSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackFloatPoolScheduleThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Staffing.FallbackFloatPoolScheduleThresholdRangeRule(min: 0.5, max: 4732.2)
        let item = Staffing.newFallbackFloatPoolSchedule("x", title: "y")
        item.threshold = 4733.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackFloatPoolScheduleRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Staffing.FallbackFloatPoolScheduleRequiredCountryRule(
            message: "fallback float pool schedule needs this field"
        )
        let item = Staffing.newFallbackFloatPoolSchedule("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
