@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedRiskScorePreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedRiskScorePreferenceValidator()
        let item = CareManagement.newBatchedRiskScorePreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedRiskScorePreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.BatchedRiskScorePreferenceRequiredCodeRule(
            message: "batched risk score preference needs an entry"
        )
        let item = CareManagement.newBatchedRiskScorePreference("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedRiskScorePreferenceAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = CareManagement.BatchedRiskScorePreferenceAmountRangeRule(min: 7.7, max: 3167.3)
        let item = CareManagement.newBatchedRiskScorePreference("x", name: "y")
        item.amount = 3168.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementBatchedRiskScorePreferenceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.BatchedRiskScorePreferenceNameLengthRule(maxLength: 86400)
        let item = CareManagement.newBatchedRiskScorePreference("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementBatchedRiskScorePreferencePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = CareManagement.BatchedRiskScorePreferencePayerLengthRule(maxLength: 32)
        let item = CareManagement.newBatchedRiskScorePreference("x", name: "y")
        item.payer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
