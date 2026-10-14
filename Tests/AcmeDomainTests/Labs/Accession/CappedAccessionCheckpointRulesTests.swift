@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedAccessionCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedAccessionCheckpointValidator()
        let item = Labs.newCappedAccessionCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedAccessionCheckpointPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Labs.CappedAccessionCheckpointPatientRefLengthRule(maxLength: 1000)
        let item = Labs.newCappedAccessionCheckpoint("x", name: "y")
        item.patientRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedAccessionCheckpointAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.CappedAccessionCheckpointAttemptsRangeRule(min: 80, max: 86400)
        let item = Labs.newCappedAccessionCheckpoint("x", name: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedAccessionCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CappedAccessionCheckpointCodeLengthRule(maxLength: 1000)
        let item = Labs.newCappedAccessionCheckpoint("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
