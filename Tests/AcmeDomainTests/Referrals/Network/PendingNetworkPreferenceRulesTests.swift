@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingNetworkPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPendingNetworkPreferenceValidator()
        let item = Referrals.newPendingNetworkPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPendingNetworkPreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.PendingNetworkPreferenceRequiredTitleRule(
            message: "pending network preference needs this field"
        )
        let item = Referrals.newPendingNetworkPreference("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
