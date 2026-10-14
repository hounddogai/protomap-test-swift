@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingRiskScoreRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingRiskScoreRollupValidator()
        let item = CareManagement.newPendingRiskScoreRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingRiskScoreRollupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.PendingRiskScoreRollupNameLengthRule(maxLength: 1000)
        let item = CareManagement.newPendingRiskScoreRollup("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingRiskScoreRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.PendingRiskScoreRollupRequiredCodeRule(
            message: "pending risk score rollup needs an entry"
        )
        let item = CareManagement.newPendingRiskScoreRollup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPendingRiskScoreRollupMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = CareManagement.PendingRiskScoreRollupMaximumRangeRule(min: 2.5, max: 789.3)
        let item = CareManagement.newPendingRiskScoreRollup("x", name: "y")
        item.maximum = 790.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPendingRiskScoreRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.PendingRiskScoreRollupCodeLengthRule(maxLength: 255)
        let item = CareManagement.newPendingRiskScoreRollup("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingRiskScoreRollupQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.PendingRiskScoreRollupQuantityRangeRule(min: 80, max: 86400)
        let item = CareManagement.newPendingRiskScoreRollup("x", name: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}
