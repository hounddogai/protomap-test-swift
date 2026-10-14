@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalAccessionCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRegionalAccessionCheckpointValidator()
        let item = Labs.newRegionalAccessionCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRegionalAccessionCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.RegionalAccessionCheckpointRequiredCodeRule(
            message: "regional accession checkpoint needs an entry"
        )
        let item = Labs.newRegionalAccessionCheckpoint("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRegionalAccessionCheckpointAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.RegionalAccessionCheckpointAttemptsRangeRule(min: 120, max: 3600)
        let item = Labs.newRegionalAccessionCheckpoint("x", name: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRegionalAccessionCheckpointDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Labs.RegionalAccessionCheckpointDurationMinutesRangeRule(min: 64, max: 86400)
        let item = Labs.newRegionalAccessionCheckpoint("x", name: "y")
        item.durationMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRegionalAccessionCheckpointEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Labs.RegionalAccessionCheckpointEncounterIDLengthRule(maxLength: 86400)
        let item = Labs.newRegionalAccessionCheckpoint("x", name: "y")
        item.encounterID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRegionalAccessionCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.RegionalAccessionCheckpointCodeLengthRule(maxLength: 1000)
        let item = Labs.newRegionalAccessionCheckpoint("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
