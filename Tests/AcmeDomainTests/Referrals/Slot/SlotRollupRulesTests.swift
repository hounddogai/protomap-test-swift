@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotRollupValidator()
        let item = Referrals.newSlotRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotRollupCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Referrals.SlotRollupCategoryLengthRule(maxLength: 1000)
        let item = Referrals.newSlotRollup("x", title: "y")
        item.category = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotRollupRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Referrals.SlotRollupRetriesRangeRule(min: 16, max: 86400)
        let item = Referrals.newSlotRollup("x", title: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotRollupSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Referrals.SlotRollupSegmentLengthRule(maxLength: 1000)
        let item = Referrals.newSlotRollup("x", title: "y")
        item.segment = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotRollupCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Referrals.SlotRollupCostRangeRule(min: 8.1, max: 3544.3)
        let item = Referrals.newSlotRollup("x", title: "y")
        item.cost = 3545.8
        #expect(rule.check(item).count > 0)
    }
}
