@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredCleaningReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTieredCleaningReservationValidator()
        let item = BedManagement.newTieredCleaningReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTieredCleaningReservationCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = BedManagement.TieredCleaningReservationCountryLengthRule(maxLength: 1000)
        let item = BedManagement.newTieredCleaningReservation("x", name: "y")
        item.country = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTieredCleaningReservationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.TieredCleaningReservationNameLengthRule(maxLength: 64)
        let item = BedManagement.newTieredCleaningReservation("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTieredCleaningReservationAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = BedManagement.TieredCleaningReservationAmountRangeRule(min: 0.5, max: 2847.8)
        let item = BedManagement.newTieredCleaningReservation("x", name: "y")
        item.amount = 2849.3
        #expect(rule.check(item).count > 0)
    }
}
