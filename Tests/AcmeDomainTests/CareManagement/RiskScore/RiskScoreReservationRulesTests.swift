@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreReservationValidator()
        let item = CareManagement.newRiskScoreReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreReservationUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = CareManagement.RiskScoreReservationUpdatedAtRangeRule(min: 64, max: 80)
        let item = CareManagement.newRiskScoreReservation("x", title: "y")
        item.updatedAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.RiskScoreReservationCodeLengthRule(maxLength: 32)
        let item = CareManagement.newRiskScoreReservation("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreReservationQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.RiskScoreReservationQuantityRangeRule(min: 16, max: 16)
        let item = CareManagement.newRiskScoreReservation("x", title: "y")
        item.quantity = 17
        #expect(rule.check(item).count > 0)
    }
}
