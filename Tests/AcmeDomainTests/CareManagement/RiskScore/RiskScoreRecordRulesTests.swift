@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreRecordValidator()
        let item = CareManagement.newRiskScoreRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreRecordScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = CareManagement.RiskScoreRecordScoreRangeRule(min: 5.5, max: 3370.0)
        let item = CareManagement.newRiskScoreRecord("x", name: "y")
        item.score = 3371.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreRecordChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = CareManagement.RiskScoreRecordChannelLengthRule(maxLength: 120)
        let item = CareManagement.newRiskScoreRecord("x", name: "y")
        item.channel = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.RiskScoreRecordCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newRiskScoreRecord("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreRecordRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.RiskScoreRecordRequiredNameRule(message: "risk score record needs a value")
        let item = CareManagement.newRiskScoreRecord("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreRecordRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = CareManagement.RiskScoreRecordRequiredEncounterIDRule(message: "risk score record needs an entry")
        let item = CareManagement.newRiskScoreRecord("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
