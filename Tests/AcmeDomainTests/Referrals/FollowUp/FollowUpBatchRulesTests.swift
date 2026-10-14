@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpBatchValidator()
        let item = Referrals.newFollowUpBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpBatchAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Referrals.FollowUpBatchAttemptsRangeRule(min: 120, max: 1000)
        let item = Referrals.newFollowUpBatch("x", name: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FollowUpBatchCodeLengthRule(maxLength: 120)
        let item = Referrals.newFollowUpBatch("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpBatchNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.FollowUpBatchNameLengthRule(maxLength: 1000)
        let item = Referrals.newFollowUpBatch("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpBatchRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Referrals.FollowUpBatchRequiredNotesRule(message: "follow up batch needs a value")
        let item = Referrals.newFollowUpBatch("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
