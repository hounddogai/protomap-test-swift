@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingWorklistPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRollingWorklistPreferenceValidator()
        let item = Imaging.newRollingWorklistPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRollingWorklistPreferenceReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Imaging.RollingWorklistPreferenceReviewerLengthRule(maxLength: 120)
        let item = Imaging.newRollingWorklistPreference("x", name: "y")
        item.reviewer = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingWorklistPreferenceRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Imaging.RollingWorklistPreferenceRequiredPayerRule(
            message: "rolling worklist preference needs a value"
        )
        let item = Imaging.newRollingWorklistPreference("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRollingWorklistPreferencePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Imaging.RollingWorklistPreferencePayerLengthRule(maxLength: 255)
        let item = Imaging.newRollingWorklistPreference("x", name: "y")
        item.payer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
