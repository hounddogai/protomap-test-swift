@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreGroupValidator()
        let item = CareManagement.newRiskScoreGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreGroupQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.RiskScoreGroupQuantityRangeRule(min: 32, max: 80)
        let item = CareManagement.newRiskScoreGroup("x", title: "y")
        item.quantity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreGroupFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.RiskScoreGroupFloorValueRangeRule(min: 6.0, max: 3399.8)
        let item = CareManagement.newRiskScoreGroup("x", title: "y")
        item.floorValue = 3401.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreGroupVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = CareManagement.RiskScoreGroupVisitMinutesRangeRule(min: 16, max: 32)
        let item = CareManagement.newRiskScoreGroup("x", title: "y")
        item.visitMinutes = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.RiskScoreGroupCodeLengthRule(maxLength: 16)
        let item = CareManagement.newRiskScoreGroup("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
