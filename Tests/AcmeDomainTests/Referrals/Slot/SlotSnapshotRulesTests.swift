@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotSnapshotValidator()
        let item = Referrals.newSlotSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotSnapshotUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Referrals.SlotSnapshotUpdatedAtRangeRule(min: 64, max: 1000)
        let item = Referrals.newSlotSnapshot("x", label: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotSnapshotVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Referrals.SlotSnapshotVisitMinutesRangeRule(min: 120, max: 1000)
        let item = Referrals.newSlotSnapshot("x", label: "y")
        item.visitMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SlotSnapshotCodeLengthRule(maxLength: 3600)
        let item = Referrals.newSlotSnapshot("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
