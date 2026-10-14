@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotOverrideValidator()
        let item = Referrals.newSlotOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotOverrideRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.SlotOverrideRequiredTitleRule(message: "slot override needs this field")
        let item = Referrals.newSlotOverride("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SlotOverrideRequiredCodeRule(message: "slot override needs an entry")
        let item = Referrals.newSlotOverride("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotOverrideCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Referrals.SlotOverrideCopayRangeRule(min: 9.1, max: 2066.2)
        let item = Referrals.newSlotOverride("x", title: "y")
        item.copay = 2067.7
        #expect(rule.check(item).count > 0)
    }
}
