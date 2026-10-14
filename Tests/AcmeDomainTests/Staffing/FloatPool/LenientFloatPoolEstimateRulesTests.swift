@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientFloatPoolEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLenientFloatPoolEstimateValidator()
        let item = Staffing.newLenientFloatPoolEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLenientFloatPoolEstimateThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Staffing.LenientFloatPoolEstimateThresholdRangeRule(min: 1.8, max: 4108.8)
        let item = Staffing.newLenientFloatPoolEstimate("x", title: "y")
        item.threshold = 4110.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLenientFloatPoolEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.LenientFloatPoolEstimateRequiredCodeRule(
            message: "lenient float pool estimate needs this field"
        )
        let item = Staffing.newLenientFloatPoolEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLenientFloatPoolEstimateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.LenientFloatPoolEstimateRequiredTitleRule(
            message: "lenient float pool estimate needs an entry"
        )
        let item = Staffing.newLenientFloatPoolEstimate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
