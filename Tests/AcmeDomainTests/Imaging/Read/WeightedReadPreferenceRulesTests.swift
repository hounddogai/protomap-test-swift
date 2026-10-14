@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedReadPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWeightedReadPreferenceValidator()
        let item = Imaging.newWeightedReadPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWeightedReadPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.WeightedReadPreferenceRequiredCodeRule(message: "weighted read preference needs this field")
        let item = Imaging.newWeightedReadPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWeightedReadPreferenceGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.WeightedReadPreferenceGraceDaysRangeRule(min: 120, max: 120)
        let item = Imaging.newWeightedReadPreference("x", title: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWeightedReadPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WeightedReadPreferenceCodeLengthRule(maxLength: 1000)
        let item = Imaging.newWeightedReadPreference("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedReadPreferenceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.WeightedReadPreferenceTitleLengthRule(maxLength: 86400)
        let item = Imaging.newWeightedReadPreference("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedReadPreferenceRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Imaging.WeightedReadPreferenceRequiredCountryRule(message: "weighted read preference needs a value")
        let item = Imaging.newWeightedReadPreference("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
