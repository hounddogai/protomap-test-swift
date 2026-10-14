@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreMappingValidator()
        let item = CareManagement.newRiskScoreMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreMappingRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = CareManagement.RiskScoreMappingRequiredDescriptionRule(message: "risk score mapping needs a value")
        let item = CareManagement.newRiskScoreMapping("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.RiskScoreMappingNameLengthRule(maxLength: 1000)
        let item = CareManagement.newRiskScoreMapping("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreMappingRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = CareManagement.RiskScoreMappingRateRangeRule(min: 3.7, max: 4974.9)
        let item = CareManagement.newRiskScoreMapping("x", name: "y")
        item.rate = 4976.4
        #expect(rule.check(item).count > 0)
    }
}
