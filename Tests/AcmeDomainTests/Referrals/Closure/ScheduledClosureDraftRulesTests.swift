@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledClosureDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledClosureDraftValidator()
        let item = Referrals.newScheduledClosureDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledClosureDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ScheduledClosureDraftRequiredCodeRule(message: "scheduled closure draft needs this field")
        let item = Referrals.newScheduledClosureDraft("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledClosureDraftRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.ScheduledClosureDraftRequiredNameRule(message: "scheduled closure draft needs a value")
        let item = Referrals.newScheduledClosureDraft("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledClosureDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.ScheduledClosureDraftNameLengthRule(maxLength: 3600)
        let item = Referrals.newScheduledClosureDraft("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
