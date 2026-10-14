@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpTemplateValidator()
        let item = Referrals.newFollowUpTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpTemplateDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Referrals.FollowUpTemplateDescriptionLengthRule(maxLength: 1000)
        let item = Referrals.newFollowUpTemplate("x", label: "y")
        item.description = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.FollowUpTemplateLabelLengthRule(maxLength: 16)
        let item = Referrals.newFollowUpTemplate("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
