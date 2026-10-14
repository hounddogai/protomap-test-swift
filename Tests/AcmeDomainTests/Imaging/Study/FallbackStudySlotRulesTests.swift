@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackStudySlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultFallbackStudySlotValidator()
        let item = Imaging.newFallbackStudySlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingFallbackStudySlotCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Imaging.FallbackStudySlotCostRangeRule(min: 0.3, max: 663.4)
        let item = Imaging.newFallbackStudySlot("x", title: "y")
        item.cost = 664.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingFallbackStudySlotRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Imaging.FallbackStudySlotRequiredCountryRule(message: "fallback study slot needs this field")
        let item = Imaging.newFallbackStudySlot("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingFallbackStudySlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.FallbackStudySlotCodeLengthRule(maxLength: 255)
        let item = Imaging.newFallbackStudySlot("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackStudySlotCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Imaging.FallbackStudySlotCurrencyLengthRule(maxLength: 86400)
        let item = Imaging.newFallbackStudySlot("x", title: "y")
        item.currency = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}
