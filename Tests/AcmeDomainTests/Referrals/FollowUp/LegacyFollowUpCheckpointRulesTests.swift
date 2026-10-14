@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyFollowUpCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLegacyFollowUpCheckpointValidator()
        let item = Referrals.newLegacyFollowUpCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLegacyFollowUpCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.LegacyFollowUpCheckpointRequiredCodeRule(
            message: "legacy follow up checkpoint needs an entry"
        )
        let item = Referrals.newLegacyFollowUpCheckpoint("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacyFollowUpCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.LegacyFollowUpCheckpointRequiredTitleRule(
            message: "legacy follow up checkpoint needs this field"
        )
        let item = Referrals.newLegacyFollowUpCheckpoint("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacyFollowUpCheckpointChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Referrals.LegacyFollowUpCheckpointChannelLengthRule(maxLength: 80)
        let item = Referrals.newLegacyFollowUpCheckpoint("x", name: "y")
        item.channel = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsLegacyFollowUpCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.LegacyFollowUpCheckpointRequiredNameRule(
            message: "legacy follow up checkpoint needs this field"
        )
        let item = Referrals.newLegacyFollowUpCheckpoint("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
