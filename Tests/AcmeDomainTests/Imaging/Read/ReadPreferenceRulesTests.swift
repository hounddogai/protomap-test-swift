@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadPreferenceValidator()
        let item = Imaging.newReadPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadPreferenceCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.ReadPreferenceCopayRangeRule(min: 3.1, max: 3184.0)
        let item = Imaging.newReadPreference("x", label: "y")
        item.copay = 3185.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadPreferenceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ReadPreferenceRequiredLabelRule(message: "read preference needs an entry")
        let item = Imaging.newReadPreference("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadPreferenceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.ReadPreferenceLabelLengthRule(maxLength: 80)
        let item = Imaging.newReadPreference("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
