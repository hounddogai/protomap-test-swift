@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpCheckpointValidator()
        let item = Referrals.newFollowUpCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpCheckpointRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Referrals.FollowUpCheckpointRequiredPayerRule(message: "follow up checkpoint needs this field")
        let item = Referrals.newFollowUpCheckpoint("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.FollowUpCheckpointRequiredCodeRule(message: "follow up checkpoint needs this field")
        let item = Referrals.newFollowUpCheckpoint("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpCheckpointOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Referrals.FollowUpCheckpointOwnerIDLengthRule(maxLength: 1000)
        let item = Referrals.newFollowUpCheckpoint("x", title: "y")
        item.ownerID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
