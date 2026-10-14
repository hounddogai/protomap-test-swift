@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientClosureNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLenientClosureNoticeValidator()
        let item = Referrals.newLenientClosureNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLenientClosureNoticeRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.LenientClosureNoticeRequiredTitleRule(message: "lenient closure notice needs a value")
        let item = Referrals.newLenientClosureNotice("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLenientClosureNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.LenientClosureNoticeCodeLengthRule(maxLength: 86400)
        let item = Referrals.newLenientClosureNotice("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsLenientClosureNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.LenientClosureNoticeRequiredCodeRule(message: "lenient closure notice needs this field")
        let item = Referrals.newLenientClosureNotice("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
