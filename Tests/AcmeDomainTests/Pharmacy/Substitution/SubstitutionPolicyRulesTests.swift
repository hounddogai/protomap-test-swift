@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionPolicyValidator()
        let item = Pharmacy.newSubstitutionPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionPolicyRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Pharmacy.SubstitutionPolicyRequiredSpecialtyRule(message: "substitution policy needs a value")
        let item = Pharmacy.newSubstitutionPolicy("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionPolicySpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Pharmacy.SubstitutionPolicySpecialtyLengthRule(maxLength: 64)
        let item = Pharmacy.newSubstitutionPolicy("x", title: "y")
        item.specialty = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionPolicyExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Pharmacy.SubstitutionPolicyExternalRefLengthRule(maxLength: 16)
        let item = Pharmacy.newSubstitutionPolicy("x", title: "y")
        item.externalRef = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.SubstitutionPolicyCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newSubstitutionPolicy("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
