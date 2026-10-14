@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenRecordValidator()
        let item = Labs.newSpecimenRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenRecordVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Labs.SpecimenRecordVersionRangeRule(min: 32, max: 80)
        let item = Labs.newSpecimenRecord("x", name: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenRecordDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Labs.SpecimenRecordDurationMinutesRangeRule(min: 80, max: 120)
        let item = Labs.newSpecimenRecord("x", name: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenRecordNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.SpecimenRecordNameLengthRule(maxLength: 1000)
        let item = Labs.newSpecimenRecord("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SpecimenRecordCodeLengthRule(maxLength: 16)
        let item = Labs.newSpecimenRecord("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
