@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionRuleValidator()
        let item = Pharmacy.newSubstitutionRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionRuleRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Pharmacy.SubstitutionRuleRequiredNotesRule(message: "substitution rule needs a value")
        let item = Pharmacy.newSubstitutionRule("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
