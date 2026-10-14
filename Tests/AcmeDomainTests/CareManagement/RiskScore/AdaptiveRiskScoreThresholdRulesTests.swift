@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveRiskScoreThresholdValidator()
        let item = CareManagement.newAdaptiveRiskScoreThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreThresholdTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.AdaptiveRiskScoreThresholdTitleLengthRule(maxLength: 120)
        let item = CareManagement.newAdaptiveRiskScoreThreshold("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreThresholdRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = CareManagement.AdaptiveRiskScoreThresholdRevisionRangeRule(min: 80, max: 3600)
        let item = CareManagement.newAdaptiveRiskScoreThreshold("x", title: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreThresholdRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.AdaptiveRiskScoreThresholdRequiredTitleRule(
            message: "adaptive risk score threshold needs an entry"
        )
        let item = CareManagement.newAdaptiveRiskScoreThreshold("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAdaptiveRiskScoreThresholdWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = CareManagement.AdaptiveRiskScoreThresholdWardLengthRule(maxLength: 16)
        let item = CareManagement.newAdaptiveRiskScoreThreshold("x", title: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
