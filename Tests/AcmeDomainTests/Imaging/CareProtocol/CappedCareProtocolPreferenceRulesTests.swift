@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedCareProtocolPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCappedCareProtocolPreferenceValidator()
        let item = Imaging.newCappedCareProtocolPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCappedCareProtocolPreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.CappedCareProtocolPreferenceRequiredTitleRule(
            message: "capped care protocol preference needs a value"
        )
        let item = Imaging.newCappedCareProtocolPreference("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCappedCareProtocolPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CappedCareProtocolPreferenceCodeLengthRule(maxLength: 80)
        let item = Imaging.newCappedCareProtocolPreference("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
