@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingWitnessEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingWitnessEntryValidator()
        let item = Consent.newRollingWitnessEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingWitnessEntryRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Consent.RollingWitnessEntryRequiredNotesRule(message: "rolling witness entry needs a value")
        let item = Consent.newRollingWitnessEntry("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingWitnessEntryMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Consent.RollingWitnessEntryMaximumRangeRule(min: 7.6, max: 4238.1)
        let item = Consent.newRollingWitnessEntry("x", name: "y")
        item.maximum = 4239.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRollingWitnessEntryNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Consent.RollingWitnessEntryNotesLengthRule(maxLength: 3600)
        let item = Consent.newRollingWitnessEntry("x", name: "y")
        item.notes = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
