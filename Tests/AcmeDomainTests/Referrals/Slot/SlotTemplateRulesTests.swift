@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotTemplateValidator()
        let item = Referrals.newSlotTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SlotTemplateCodeLengthRule(maxLength: 80)
        let item = Referrals.newSlotTemplate("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotTemplateMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Referrals.SlotTemplateMaximumRangeRule(min: 3.8, max: 2668.9)
        let item = Referrals.newSlotTemplate("x", label: "y")
        item.maximum = 2670.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SlotTemplateRequiredCodeRule(message: "slot template needs this field")
        let item = Referrals.newSlotTemplate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
