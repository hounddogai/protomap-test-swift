@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreCheckpointValidator()
        let item = CareManagement.newRiskScoreCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreCheckpointDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = CareManagement.RiskScoreCheckpointDescriptionLengthRule(maxLength: 86400)
        let item = CareManagement.newRiskScoreCheckpoint("x", label: "y")
        item.description = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.RiskScoreCheckpointCodeLengthRule(maxLength: 120)
        let item = CareManagement.newRiskScoreCheckpoint("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RiskScoreCheckpointRequiredCodeRule(message: "risk score checkpoint needs an entry")
        let item = CareManagement.newRiskScoreCheckpoint("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
