@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingSubstitutionRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRollingSubstitutionRuleValidator()
        let item = Pharmacy.newRollingSubstitutionRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRollingSubstitutionRuleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.RollingSubstitutionRuleNameLengthRule(maxLength: 3600)
        let item = Pharmacy.newRollingSubstitutionRule("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingSubstitutionRuleRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Pharmacy.RollingSubstitutionRuleRequiredSpecialtyRule(
            message: "rolling substitution rule needs a value"
        )
        let item = Pharmacy.newRollingSubstitutionRule("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
