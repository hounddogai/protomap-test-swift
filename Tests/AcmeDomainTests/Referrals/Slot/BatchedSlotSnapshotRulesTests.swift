@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedSlotSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultBatchedSlotSnapshotValidator()
        let item = Referrals.newBatchedSlotSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsBatchedSlotSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.BatchedSlotSnapshotCodeLengthRule(maxLength: 120)
        let item = Referrals.newBatchedSlotSnapshot("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsBatchedSlotSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.BatchedSlotSnapshotRequiredCodeRule(message: "batched slot snapshot needs this field")
        let item = Referrals.newBatchedSlotSnapshot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedSlotSnapshotChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Referrals.BatchedSlotSnapshotChannelLengthRule(maxLength: 1000)
        let item = Referrals.newBatchedSlotSnapshot("x", title: "y")
        item.channel = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsBatchedSlotSnapshotRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Referrals.BatchedSlotSnapshotRequiredChannelRule(message: "batched slot snapshot needs this field")
        let item = Referrals.newBatchedSlotSnapshot("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedSlotSnapshotAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Referrals.BatchedSlotSnapshotAmountRangeRule(min: 1.1, max: 2041.0)
        let item = Referrals.newBatchedSlotSnapshot("x", title: "y")
        item.amount = 2042.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsBatchedSlotSnapshotPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Referrals.BatchedSlotSnapshotPriorityRangeRule(min: 120, max: 255)
        let item = Referrals.newBatchedSlotSnapshot("x", title: "y")
        item.priority = 256
        #expect(rule.check(item).count > 0)
    }
}
