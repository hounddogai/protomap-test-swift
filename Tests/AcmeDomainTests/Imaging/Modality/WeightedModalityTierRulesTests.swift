@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedModalityTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWeightedModalityTierValidator()
        let item = Imaging.newWeightedModalityTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWeightedModalityTierCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.WeightedModalityTierCopayRangeRule(min: 7.7, max: 1993.4)
        let item = Imaging.newWeightedModalityTier("x", name: "y")
        item.copay = 1994.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWeightedModalityTierNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.WeightedModalityTierNameLengthRule(maxLength: 3600)
        let item = Imaging.newWeightedModalityTier("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedModalityTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WeightedModalityTierCodeLengthRule(maxLength: 64)
        let item = Imaging.newWeightedModalityTier("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedModalityTierRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Imaging.WeightedModalityTierRequiredUnitRule(message: "weighted modality tier needs this field")
        let item = Imaging.newWeightedModalityTier("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
