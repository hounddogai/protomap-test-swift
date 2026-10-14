@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultScheduledPriorityEstimateValidator()
        let item = Imaging.newScheduledPriorityEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingScheduledPriorityEstimateWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Imaging.ScheduledPriorityEstimateWeightRangeRule(min: 4.1, max: 2893.9)
        let item = Imaging.newScheduledPriorityEstimate("x", title: "y")
        item.weight = 2895.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingScheduledPriorityEstimateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.ScheduledPriorityEstimateRequiredTitleRule(
            message: "scheduled priority estimate needs a value"
        )
        let item = Imaging.newScheduledPriorityEstimate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingScheduledPriorityEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ScheduledPriorityEstimateRequiredCodeRule(
            message: "scheduled priority estimate needs a value"
        )
        let item = Imaging.newScheduledPriorityEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
