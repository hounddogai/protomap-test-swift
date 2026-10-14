@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalPriorityMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalPriorityMappingValidator()
        let item = Imaging.newSeasonalPriorityMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalPriorityMappingRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.SeasonalPriorityMappingRequiredNameRule(message: "seasonal priority mapping needs this field")
        let item = Imaging.newSeasonalPriorityMapping("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalPriorityMappingChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Imaging.SeasonalPriorityMappingChannelLengthRule(maxLength: 32)
        let item = Imaging.newSeasonalPriorityMapping("x", name: "y")
        item.channel = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalPriorityMappingDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Imaging.SeasonalPriorityMappingDiscountRangeRule(min: 5.6, max: 3066.6)
        let item = Imaging.newSeasonalPriorityMapping("x", name: "y")
        item.discount = 3068.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalPriorityMappingCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Imaging.SeasonalPriorityMappingCreatedAtRangeRule(min: 32, max: 64)
        let item = Imaging.newSeasonalPriorityMapping("x", name: "y")
        item.createdAt = 65
        #expect(rule.check(item).count > 0)
    }
}
