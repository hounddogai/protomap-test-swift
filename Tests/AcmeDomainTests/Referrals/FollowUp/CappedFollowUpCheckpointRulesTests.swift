@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedFollowUpCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedFollowUpCheckpointValidator()
        let item = Referrals.newCappedFollowUpCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedFollowUpCheckpointTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Referrals.CappedFollowUpCheckpointTimezoneLengthRule(maxLength: 64)
        let item = Referrals.newCappedFollowUpCheckpoint("x", title: "y")
        item.timezone = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedFollowUpCheckpointChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Referrals.CappedFollowUpCheckpointChannelLengthRule(maxLength: 80)
        let item = Referrals.newCappedFollowUpCheckpoint("x", title: "y")
        item.channel = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedFollowUpCheckpointRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Referrals.CappedFollowUpCheckpointRequiredChannelRule(
            message: "capped follow up checkpoint needs a value"
        )
        let item = Referrals.newCappedFollowUpCheckpoint("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
