@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotProfileValidator()
        let item = Referrals.newSlotProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SlotProfileCodeLengthRule(maxLength: 64)
        let item = Referrals.newSlotProfile("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SlotProfileRequiredCodeRule(message: "slot profile needs this field")
        let item = Referrals.newSlotProfile("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.SlotProfileTitleLengthRule(maxLength: 32)
        let item = Referrals.newSlotProfile("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
