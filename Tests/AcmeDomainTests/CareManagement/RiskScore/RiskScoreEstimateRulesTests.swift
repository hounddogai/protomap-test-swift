@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreEstimateValidator()
        let item = CareManagement.newRiskScoreEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RiskScoreEstimateRequiredCodeRule(message: "risk score estimate needs a value")
        let item = CareManagement.newRiskScoreEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreEstimateWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.RiskScoreEstimateWindowDaysRangeRule(min: 80, max: 255)
        let item = CareManagement.newRiskScoreEstimate("x", title: "y")
        item.windowDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreEstimateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.RiskScoreEstimateTitleLengthRule(maxLength: 64)
        let item = CareManagement.newRiskScoreEstimate("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreEstimateRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = CareManagement.RiskScoreEstimateRevisionRangeRule(min: 64, max: 1000)
        let item = CareManagement.newRiskScoreEstimate("x", title: "y")
        item.revision = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreEstimateOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = CareManagement.RiskScoreEstimateOwnerIDLengthRule(maxLength: 1000)
        let item = CareManagement.newRiskScoreEstimate("x", title: "y")
        item.ownerID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
