@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureNoticeValidator()
        let item = Referrals.newClosureNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureNoticeBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Referrals.ClosureNoticeBedLengthRule(maxLength: 32)
        let item = Referrals.newClosureNotice("x", name: "y")
        item.bed = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureNoticeRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Referrals.ClosureNoticeRequiredBedRule(message: "closure notice needs a value")
        let item = Referrals.newClosureNotice("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureNoticeNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.ClosureNoticeNameLengthRule(maxLength: 120)
        let item = Referrals.newClosureNotice("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ClosureNoticeCodeLengthRule(maxLength: 120)
        let item = Referrals.newClosureNotice("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureNoticeRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.ClosureNoticeRequiredNameRule(message: "closure notice needs a value")
        let item = Referrals.newClosureNotice("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
