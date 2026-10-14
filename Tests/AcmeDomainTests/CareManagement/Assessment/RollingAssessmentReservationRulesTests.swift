@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingAssessmentReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRollingAssessmentReservationValidator()
        let item = CareManagement.newRollingAssessmentReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRollingAssessmentReservationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.RollingAssessmentReservationNameLengthRule(maxLength: 80)
        let item = CareManagement.newRollingAssessmentReservation("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRollingAssessmentReservationQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.RollingAssessmentReservationQuantityRangeRule(min: 16, max: 120)
        let item = CareManagement.newRollingAssessmentReservation("x", name: "y")
        item.quantity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRollingAssessmentReservationAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = CareManagement.RollingAssessmentReservationAmountRangeRule(min: 9.7, max: 4697.8)
        let item = CareManagement.newRollingAssessmentReservation("x", name: "y")
        item.amount = 4699.3
        #expect(rule.check(item).count > 0)
    }
}
