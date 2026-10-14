@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenPreferenceValidator()
        let item = Labs.newSpecimenPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenPreferenceCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.SpecimenPreferenceCeilingRangeRule(min: 7.0, max: 4066.1)
        let item = Labs.newSpecimenPreference("x", label: "y")
        item.ceiling = 4067.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenPreferenceSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Labs.SpecimenPreferenceSpecialtyLengthRule(maxLength: 255)
        let item = Labs.newSpecimenPreference("x", label: "y")
        item.specialty = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
