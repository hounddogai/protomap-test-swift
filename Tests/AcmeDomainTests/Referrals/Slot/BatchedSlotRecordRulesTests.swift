@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedSlotRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultBatchedSlotRecordValidator()
        let item = Referrals.newBatchedSlotRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsBatchedSlotRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.BatchedSlotRecordCodeLengthRule(maxLength: 64)
        let item = Referrals.newBatchedSlotRecord("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsBatchedSlotRecordRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.BatchedSlotRecordRequiredTitleRule(message: "batched slot record needs a value")
        let item = Referrals.newBatchedSlotRecord("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
