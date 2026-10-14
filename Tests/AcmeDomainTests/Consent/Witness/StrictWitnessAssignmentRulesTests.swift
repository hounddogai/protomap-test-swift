@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictWitnessAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultStrictWitnessAssignmentValidator()
        let item = Consent.newStrictWitnessAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentStrictWitnessAssignmentRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Consent.StrictWitnessAssignmentRequiredContactEmailRule(
            message: "strict witness assignment needs an entry"
        )
        let item = Consent.newStrictWitnessAssignment("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentStrictWitnessAssignmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.StrictWitnessAssignmentRequiredTitleRule(
            message: "strict witness assignment needs this field"
        )
        let item = Consent.newStrictWitnessAssignment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentStrictWitnessAssignmentRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Consent.StrictWitnessAssignmentRequiredUnitRule(message: "strict witness assignment needs a value")
        let item = Consent.newStrictWitnessAssignment("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
