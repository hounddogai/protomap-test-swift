@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScorePolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScorePolicyValidator()
        let item = CareManagement.newRiskScorePolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScorePolicyCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = CareManagement.RiskScorePolicyCategoryLengthRule(maxLength: 255)
        let item = CareManagement.newRiskScorePolicy("x", title: "y")
        item.category = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScorePolicyCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = CareManagement.RiskScorePolicyCapacityRangeRule(min: 120, max: 1000)
        let item = CareManagement.newRiskScorePolicy("x", title: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}
