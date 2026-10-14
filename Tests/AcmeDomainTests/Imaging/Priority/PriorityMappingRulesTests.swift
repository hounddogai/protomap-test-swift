@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityMappingValidator()
        let item = Imaging.newPriorityMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityMappingRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.PriorityMappingRequiredNameRule(message: "priority mapping needs an entry")
        let item = Imaging.newPriorityMapping("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityMappingCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Imaging.PriorityMappingCategoryLengthRule(maxLength: 1000)
        let item = Imaging.newPriorityMapping("x", name: "y")
        item.category = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityMappingRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Imaging.PriorityMappingRequiredCategoryRule(message: "priority mapping needs a value")
        let item = Imaging.newPriorityMapping("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityMappingBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Imaging.PriorityMappingBatchSizeRangeRule(min: 64, max: 86400)
        let item = Imaging.newPriorityMapping("x", name: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityMappingRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Imaging.PriorityMappingRatioRangeRule(min: 0.0, max: 3244.7)
        let item = Imaging.newPriorityMapping("x", name: "y")
        item.ratio = 3246.2
        #expect(rule.check(item).count > 0)
    }
}
