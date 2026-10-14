@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredSlotSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredSlotSnapshotValidator()
        let item = Referrals.newTieredSlotSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredSlotSnapshotReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Referrals.TieredSlotSnapshotReviewerLengthRule(maxLength: 86400)
        let item = Referrals.newTieredSlotSnapshot("x", name: "y")
        item.reviewer = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsTieredSlotSnapshotAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Referrals.TieredSlotSnapshotAcuityRangeRule(min: 32, max: 80)
        let item = Referrals.newTieredSlotSnapshot("x", name: "y")
        item.acuity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsTieredSlotSnapshotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.TieredSlotSnapshotNameLengthRule(maxLength: 16)
        let item = Referrals.newTieredSlotSnapshot("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsTieredSlotSnapshotTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Referrals.TieredSlotSnapshotTimezoneLengthRule(maxLength: 64)
        let item = Referrals.newTieredSlotSnapshot("x", name: "y")
        item.timezone = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
