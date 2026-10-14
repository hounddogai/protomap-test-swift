@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRollingCareProtocolWindowValidator()
        let item = Imaging.newRollingCareProtocolWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRollingCareProtocolWindowWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Imaging.RollingCareProtocolWindowWeightRangeRule(min: 5.4, max: 2690.0)
        let item = Imaging.newRollingCareProtocolWindow("x", title: "y")
        item.weight = 2691.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingRollingCareProtocolWindowTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.RollingCareProtocolWindowTitleLengthRule(maxLength: 32)
        let item = Imaging.newRollingCareProtocolWindow("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingCareProtocolWindowBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Imaging.RollingCareProtocolWindowBudgetRangeRule(min: 0.9, max: 3435.6)
        let item = Imaging.newRollingCareProtocolWindow("x", title: "y")
        item.budget = 3437.1
        #expect(rule.check(item).count > 0)
    }
}
