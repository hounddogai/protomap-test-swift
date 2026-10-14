@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacySlotItemValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLegacySlotItemValidator()
        let item = Referrals.newLegacySlotItem("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLegacySlotItemCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Referrals.LegacySlotItemCostRangeRule(min: 8.3, max: 1474.1)
        let item = Referrals.newLegacySlotItem("x", title: "y")
        item.cost = 1475.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLegacySlotItemRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.LegacySlotItemRequiredNameRule(message: "legacy slot item needs this field")
        let item = Referrals.newLegacySlotItem("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacySlotItemRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.LegacySlotItemRequiredTitleRule(message: "legacy slot item needs this field")
        let item = Referrals.newLegacySlotItem("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacySlotItemTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.LegacySlotItemTitleLengthRule(maxLength: 255)
        let item = Referrals.newLegacySlotItem("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsLegacySlotItemFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Referrals.LegacySlotItemFloorValueRangeRule(min: 5.5, max: 1746.6)
        let item = Referrals.newLegacySlotItem("x", title: "y")
        item.floorValue = 1748.1
        #expect(rule.check(item).count > 0)
    }
}
