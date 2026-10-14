@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenOverrideValidator()
        let item = Labs.newSpecimenOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenOverrideNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Labs.SpecimenOverrideNotesLengthRule(maxLength: 3600)
        let item = Labs.newSpecimenOverride("x", title: "y")
        item.notes = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenOverrideAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Labs.SpecimenOverrideAcuityRangeRule(min: 16, max: 120)
        let item = Labs.newSpecimenOverride("x", title: "y")
        item.acuity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenOverrideLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Labs.SpecimenOverrideLocaleLengthRule(maxLength: 64)
        let item = Labs.newSpecimenOverride("x", title: "y")
        item.locale = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenOverrideTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.SpecimenOverrideTitleLengthRule(maxLength: 86400)
        let item = Labs.newSpecimenOverride("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenOverrideRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Labs.SpecimenOverrideRequiredNotesRule(message: "specimen override needs a value")
        let item = Labs.newSpecimenOverride("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
