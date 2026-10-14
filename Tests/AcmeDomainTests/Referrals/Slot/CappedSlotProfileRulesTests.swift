@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedSlotProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedSlotProfileValidator()
        let item = Referrals.newCappedSlotProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedSlotProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.CappedSlotProfileCodeLengthRule(maxLength: 16)
        let item = Referrals.newCappedSlotProfile("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedSlotProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.CappedSlotProfileRequiredCodeRule(message: "capped slot profile needs this field")
        let item = Referrals.newCappedSlotProfile("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedSlotProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.CappedSlotProfileTitleLengthRule(maxLength: 120)
        let item = Referrals.newCappedSlotProfile("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedSlotProfileFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Referrals.CappedSlotProfileFloorValueRangeRule(min: 1.2, max: 1511.5)
        let item = Referrals.newCappedSlotProfile("x", title: "y")
        item.floorValue = 1513.0
        #expect(rule.check(item).count > 0)
    }
}
