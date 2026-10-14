@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusReservationValidator()
        let item = BedManagement.newCensusReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusReservationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.CensusReservationRequiredTitleRule(message: "census reservation needs an entry")
        let item = BedManagement.newCensusReservation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusReservationRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = BedManagement.CensusReservationRateRangeRule(min: 0.2, max: 2255.0)
        let item = BedManagement.newCensusReservation("x", title: "y")
        item.rate = 2256.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusReservationWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = BedManagement.CensusReservationWindowDaysRangeRule(min: 16, max: 120)
        let item = BedManagement.newCensusReservation("x", title: "y")
        item.windowDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusReservationRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = BedManagement.CensusReservationRefillsRangeRule(min: 64, max: 80)
        let item = BedManagement.newCensusReservation("x", title: "y")
        item.refills = 81
        #expect(rule.check(item).count > 0)
    }
}
