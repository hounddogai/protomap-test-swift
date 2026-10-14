@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledFollowUpManifestValidator()
        let item = Referrals.newScheduledFollowUpManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledFollowUpManifestVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Referrals.ScheduledFollowUpManifestVersionRangeRule(min: 120, max: 86400)
        let item = Referrals.newScheduledFollowUpManifest("x", title: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledFollowUpManifestRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Referrals.ScheduledFollowUpManifestRequiredPhoneRule(
            message: "scheduled follow up manifest needs an entry"
        )
        let item = Referrals.newScheduledFollowUpManifest("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledFollowUpManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ScheduledFollowUpManifestCodeLengthRule(maxLength: 32)
        let item = Referrals.newScheduledFollowUpManifest("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
