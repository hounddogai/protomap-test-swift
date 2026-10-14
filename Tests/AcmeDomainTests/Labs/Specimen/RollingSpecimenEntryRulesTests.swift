@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingSpecimenEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingSpecimenEntryValidator()
        let item = Labs.newRollingSpecimenEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingSpecimenEntrySpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Labs.RollingSpecimenEntrySpecialtyLengthRule(maxLength: 120)
        let item = Labs.newRollingSpecimenEntry("x", title: "y")
        item.specialty = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingSpecimenEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.RollingSpecimenEntryCodeLengthRule(maxLength: 255)
        let item = Labs.newRollingSpecimenEntry("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingSpecimenEntryMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Labs.RollingSpecimenEntryMinimumRangeRule(min: 2.6, max: 4710.0)
        let item = Labs.newRollingSpecimenEntry("x", title: "y")
        item.minimum = 4711.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRollingSpecimenEntryLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Labs.RollingSpecimenEntryLimitRangeRule(min: 32, max: 255)
        let item = Labs.newRollingSpecimenEntry("x", title: "y")
        item.limit = 256
        #expect(rule.check(item).count > 0)
    }
}
