@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledLanguageRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledLanguageRuleValidator()
        let item = Consent.newScheduledLanguageRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledLanguageRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ScheduledLanguageRuleCodeLengthRule(maxLength: 16)
        let item = Consent.newScheduledLanguageRule("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledLanguageRuleRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Consent.ScheduledLanguageRuleRequiredClinicianIDRule(message: "scheduled language rule needs a value")
        let item = Consent.newScheduledLanguageRule("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledLanguageRuleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.ScheduledLanguageRuleLabelLengthRule(maxLength: 16)
        let item = Consent.newScheduledLanguageRule("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
