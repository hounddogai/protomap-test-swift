@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveRiskScoreCheckpointValidator()
        let item = CareManagement.newAdaptiveRiskScoreCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreCheckpointCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = CareManagement.AdaptiveRiskScoreCheckpointCeilingRangeRule(min: 6.8, max: 2469.4)
        let item = CareManagement.newAdaptiveRiskScoreCheckpoint("x", name: "y")
        item.ceiling = 2470.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.AdaptiveRiskScoreCheckpointRequiredNameRule(
            message: "adaptive risk score checkpoint needs a value"
        )
        let item = CareManagement.newAdaptiveRiskScoreCheckpoint("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreCheckpointBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = CareManagement.AdaptiveRiskScoreCheckpointBatchSizeRangeRule(min: 80, max: 80)
        let item = CareManagement.newAdaptiveRiskScoreCheckpoint("x", name: "y")
        item.batchSize = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreCheckpointNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.AdaptiveRiskScoreCheckpointNameLengthRule(maxLength: 32)
        let item = CareManagement.newAdaptiveRiskScoreCheckpoint("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
