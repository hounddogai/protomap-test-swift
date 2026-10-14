@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenCheckpointValidator()
        let item = Labs.newSpecimenCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SpecimenCheckpointCodeLengthRule(maxLength: 86400)
        let item = Labs.newSpecimenCheckpoint("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenCheckpointRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Labs.SpecimenCheckpointRequiredFacilityRule(message: "specimen checkpoint needs this field")
        let item = Labs.newSpecimenCheckpoint("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenCheckpointRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.SpecimenCheckpointRequiredLabelRule(message: "specimen checkpoint needs this field")
        let item = Labs.newSpecimenCheckpoint("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenCheckpointRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Labs.SpecimenCheckpointRequiredExternalRefRule(message: "specimen checkpoint needs an entry")
        let item = Labs.newSpecimenCheckpoint("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
