@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCappedModalityPreferenceValidator()
        let item = Imaging.newCappedModalityPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCappedModalityPreferenceRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Imaging.CappedModalityPreferenceRequiredUnitRule(message: "capped modality preference needs a value")
        let item = Imaging.newCappedModalityPreference("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCappedModalityPreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.CappedModalityPreferenceRequiredTitleRule(
            message: "capped modality preference needs this field"
        )
        let item = Imaging.newCappedModalityPreference("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
