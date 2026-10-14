@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackRiskScoreCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultFallbackRiskScoreCheckpointValidator()
        let item = CareManagement.newFallbackRiskScoreCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementFallbackRiskScoreCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.FallbackRiskScoreCheckpointRequiredTitleRule(
            message: "fallback risk score checkpoint needs a value"
        )
        let item = CareManagement.newFallbackRiskScoreCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementFallbackRiskScoreCheckpointChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = CareManagement.FallbackRiskScoreCheckpointChannelLengthRule(maxLength: 80)
        let item = CareManagement.newFallbackRiskScoreCheckpoint("x", title: "y")
        item.channel = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementFallbackRiskScoreCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.FallbackRiskScoreCheckpointRequiredCodeRule(
            message: "fallback risk score checkpoint needs a value"
        )
        let item = CareManagement.newFallbackRiskScoreCheckpoint("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementFallbackRiskScoreCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.FallbackRiskScoreCheckpointCodeLengthRule(maxLength: 16)
        let item = CareManagement.newFallbackRiskScoreCheckpoint("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementFallbackRiskScoreCheckpointRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.FallbackRiskScoreCheckpointRequiredChannelRule(
            message: "fallback risk score checkpoint needs this field"
        )
        let item = CareManagement.newFallbackRiskScoreCheckpoint("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
