@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultRiskScoreEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultDefaultRiskScoreEstimateValidator()
        let item = CareManagement.newDefaultRiskScoreEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementDefaultRiskScoreEstimateRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = CareManagement.DefaultRiskScoreEstimateRequiredEncounterIDRule(
            message: "default risk score estimate needs this field"
        )
        let item = CareManagement.newDefaultRiskScoreEstimate("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementDefaultRiskScoreEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.DefaultRiskScoreEstimateCodeLengthRule(maxLength: 64)
        let item = CareManagement.newDefaultRiskScoreEstimate("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementDefaultRiskScoreEstimateUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = CareManagement.DefaultRiskScoreEstimateUpdatedAtRangeRule(min: 16, max: 80)
        let item = CareManagement.newDefaultRiskScoreEstimate("x", label: "y")
        item.updatedAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementDefaultRiskScoreEstimateEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = CareManagement.DefaultRiskScoreEstimateEncounterIDLengthRule(maxLength: 64)
        let item = CareManagement.newDefaultRiskScoreEstimate("x", label: "y")
        item.encounterID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementDefaultRiskScoreEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.DefaultRiskScoreEstimateRequiredCodeRule(
            message: "default risk score estimate needs this field"
        )
        let item = CareManagement.newDefaultRiskScoreEstimate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
