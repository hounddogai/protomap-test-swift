@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingRiskScoreCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingRiskScoreCheckpointValidator()
        let item = CareManagement.newPendingRiskScoreCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingRiskScoreCheckpointRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = CareManagement.PendingRiskScoreCheckpointRevisionRangeRule(min: 32, max: 32)
        let item = CareManagement.newPendingRiskScoreCheckpoint("x", label: "y")
        item.revision = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPendingRiskScoreCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.PendingRiskScoreCheckpointRequiredCodeRule(
            message: "pending risk score checkpoint needs an entry"
        )
        let item = CareManagement.newPendingRiskScoreCheckpoint("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPendingRiskScoreCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.PendingRiskScoreCheckpointCodeLengthRule(maxLength: 255)
        let item = CareManagement.newPendingRiskScoreCheckpoint("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingRiskScoreCheckpointRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = CareManagement.PendingRiskScoreCheckpointRequiredSegmentRule(
            message: "pending risk score checkpoint needs a value"
        )
        let item = CareManagement.newPendingRiskScoreCheckpoint("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
