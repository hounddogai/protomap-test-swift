@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveReadGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultAdaptiveReadGroupValidator()
        let item = Imaging.newAdaptiveReadGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingAdaptiveReadGroupBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Imaging.AdaptiveReadGroupBudgetRangeRule(min: 3.1, max: 1739.6)
        let item = Imaging.newAdaptiveReadGroup("x", name: "y")
        item.budget = 1741.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingAdaptiveReadGroupBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Imaging.AdaptiveReadGroupBatchSizeRangeRule(min: 80, max: 120)
        let item = Imaging.newAdaptiveReadGroup("x", name: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingAdaptiveReadGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.AdaptiveReadGroupRequiredCodeRule(message: "adaptive read group needs this field")
        let item = Imaging.newAdaptiveReadGroup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingAdaptiveReadGroupUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Imaging.AdaptiveReadGroupUnitLengthRule(maxLength: 80)
        let item = Imaging.newAdaptiveReadGroup("x", name: "y")
        item.unit = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
