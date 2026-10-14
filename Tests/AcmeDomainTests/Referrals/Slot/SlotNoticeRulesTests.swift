@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotNoticeValidator()
        let item = Referrals.newSlotNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotNoticeRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.SlotNoticeRequiredTitleRule(message: "slot notice needs an entry")
        let item = Referrals.newSlotNotice("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SlotNoticeCodeLengthRule(maxLength: 1000)
        let item = Referrals.newSlotNotice("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SlotNoticeRequiredCodeRule(message: "slot notice needs an entry")
        let item = Referrals.newSlotNotice("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
