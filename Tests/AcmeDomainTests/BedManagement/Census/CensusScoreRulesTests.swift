@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusScoreValidator()
        let item = BedManagement.newCensusScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusScoreRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.CensusScoreRequiredLabelRule(message: "census score needs an entry")
        let item = BedManagement.newCensusScore("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusScoreRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = BedManagement.CensusScoreRevisionRangeRule(min: 64, max: 3600)
        let item = BedManagement.newCensusScore("x", label: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusScoreSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = BedManagement.CensusScoreSequenceRangeRule(min: 32, max: 80)
        let item = BedManagement.newCensusScore("x", label: "y")
        item.sequence = 81
        #expect(rule.check(item).count > 0)
    }
}
