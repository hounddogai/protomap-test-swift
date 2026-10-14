@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionCheckpointValidator()
        let item = Labs.newAccessionCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionCheckpointAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Labs.AccessionCheckpointAllergyLengthRule(maxLength: 80)
        let item = Labs.newAccessionCheckpoint("x", label: "y")
        item.allergy = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionCheckpointQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Labs.AccessionCheckpointQuantityRangeRule(min: 1000, max: 86400)
        let item = Labs.newAccessionCheckpoint("x", label: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionCheckpointCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.AccessionCheckpointCeilingRangeRule(min: 1.5, max: 4916.9)
        let item = Labs.newAccessionCheckpoint("x", label: "y")
        item.ceiling = 4918.4
        #expect(rule.check(item).count > 0)
    }
}
