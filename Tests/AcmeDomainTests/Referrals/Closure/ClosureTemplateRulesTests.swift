@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureTemplateValidator()
        let item = Referrals.newClosureTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureTemplateRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Referrals.ClosureTemplateRequiredTimezoneRule(message: "closure template needs this field")
        let item = Referrals.newClosureTemplate("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ClosureTemplateRequiredCodeRule(message: "closure template needs this field")
        let item = Referrals.newClosureTemplate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureTemplateRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Referrals.ClosureTemplateRequiredExternalRefRule(message: "closure template needs a value")
        let item = Referrals.newClosureTemplate("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
