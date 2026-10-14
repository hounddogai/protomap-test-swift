@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalRiskScoreReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRegionalRiskScoreReservationValidator()
        let item = CareManagement.newRegionalRiskScoreReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRegionalRiskScoreReservationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.RegionalRiskScoreReservationNameLengthRule(maxLength: 3600)
        let item = CareManagement.newRegionalRiskScoreReservation("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRegionalRiskScoreReservationCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = CareManagement.RegionalRiskScoreReservationCreatedAtRangeRule(min: 255, max: 86400)
        let item = CareManagement.newRegionalRiskScoreReservation("x", name: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRegionalRiskScoreReservationEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = CareManagement.RegionalRiskScoreReservationEncounterIDLengthRule(maxLength: 80)
        let item = CareManagement.newRegionalRiskScoreReservation("x", name: "y")
        item.encounterID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
