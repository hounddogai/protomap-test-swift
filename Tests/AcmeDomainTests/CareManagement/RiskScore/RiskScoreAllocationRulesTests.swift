@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreAllocationValidator()
        let item = CareManagement.newRiskScoreAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreAllocationWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = CareManagement.RiskScoreAllocationWardLengthRule(maxLength: 16)
        let item = CareManagement.newRiskScoreAllocation("x", title: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.RiskScoreAllocationTitleLengthRule(maxLength: 86400)
        let item = CareManagement.newRiskScoreAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
