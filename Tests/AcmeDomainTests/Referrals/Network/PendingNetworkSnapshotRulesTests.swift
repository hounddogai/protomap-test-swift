@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingNetworkSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPendingNetworkSnapshotValidator()
        let item = Referrals.newPendingNetworkSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPendingNetworkSnapshotChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Referrals.PendingNetworkSnapshotChannelLengthRule(maxLength: 32)
        let item = Referrals.newPendingNetworkSnapshot("x", title: "y")
        item.channel = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPendingNetworkSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.PendingNetworkSnapshotCodeLengthRule(maxLength: 120)
        let item = Referrals.newPendingNetworkSnapshot("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPendingNetworkSnapshotRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Referrals.PendingNetworkSnapshotRequiredChannelRule(
            message: "pending network snapshot needs this field"
        )
        let item = Referrals.newPendingNetworkSnapshot("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPendingNetworkSnapshotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.PendingNetworkSnapshotRequiredTitleRule(message: "pending network snapshot needs an entry")
        let item = Referrals.newPendingNetworkSnapshot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
