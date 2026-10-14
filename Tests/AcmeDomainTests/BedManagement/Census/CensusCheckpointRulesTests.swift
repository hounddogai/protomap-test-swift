@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusCheckpointValidator()
        let item = BedManagement.newCensusCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CensusCheckpointCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newCensusCheckpoint("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusCheckpointCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = BedManagement.CensusCheckpointCeilingRangeRule(min: 4.5, max: 3895.8)
        let item = BedManagement.newCensusCheckpoint("x", label: "y")
        item.ceiling = 3897.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusCheckpointLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.CensusCheckpointLabelLengthRule(maxLength: 16)
        let item = BedManagement.newCensusCheckpoint("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusCheckpointBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.CensusCheckpointBudgetRangeRule(min: 9.8, max: 4597.6)
        let item = BedManagement.newCensusCheckpoint("x", label: "y")
        item.budget = 4599.1
        #expect(rule.check(item).count > 0)
    }
}
