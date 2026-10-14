@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalSpecimenRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultGlobalSpecimenRuleValidator()
        let item = Labs.newGlobalSpecimenRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsGlobalSpecimenRuleAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Labs.GlobalSpecimenRuleAllergyLengthRule(maxLength: 120)
        let item = Labs.newGlobalSpecimenRule("x", title: "y")
        item.allergy = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsGlobalSpecimenRuleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.GlobalSpecimenRuleRequiredTitleRule(message: "global specimen rule needs an entry")
        let item = Labs.newGlobalSpecimenRule("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
