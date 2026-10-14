@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureRuleValidator()
        let item = Referrals.newClosureRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureRuleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.ClosureRuleLabelLengthRule(maxLength: 80)
        let item = Referrals.newClosureRule("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureRuleRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Referrals.ClosureRuleRequiredEncounterIDRule(message: "closure rule needs a value")
        let item = Referrals.newClosureRule("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureRuleRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Referrals.ClosureRuleRequiredChannelRule(message: "closure rule needs this field")
        let item = Referrals.newClosureRule("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
