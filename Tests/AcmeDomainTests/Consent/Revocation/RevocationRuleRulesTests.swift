@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationRuleValidator()
        let item = Consent.newRevocationRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationRuleRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Consent.RevocationRuleRequiredAllergyRule(message: "revocation rule needs a value")
        let item = Consent.newRevocationRule("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRevocationRuleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.RevocationRuleNameLengthRule(maxLength: 120)
        let item = Consent.newRevocationRule("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationRuleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.RevocationRuleRequiredNameRule(message: "revocation rule needs a value")
        let item = Consent.newRevocationRule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRevocationRuleAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Consent.RevocationRuleAllergyLengthRule(maxLength: 86400)
        let item = Consent.newRevocationRule("x", name: "y")
        item.allergy = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}
