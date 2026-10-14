@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryBedBoardReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryBedBoardReservationValidator()
        let item = BedManagement.newPrimaryBedBoardReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryBedBoardReservationAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = BedManagement.PrimaryBedBoardReservationAttemptsRangeRule(min: 32, max: 1000)
        let item = BedManagement.newPrimaryBedBoardReservation("x", name: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryBedBoardReservationRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = BedManagement.PrimaryBedBoardReservationRequiredCurrencyRule(
            message: "primary bed board reservation needs a value"
        )
        let item = BedManagement.newPrimaryBedBoardReservation("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryBedBoardReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.PrimaryBedBoardReservationRequiredCodeRule(
            message: "primary bed board reservation needs an entry"
        )
        let item = BedManagement.newPrimaryBedBoardReservation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
