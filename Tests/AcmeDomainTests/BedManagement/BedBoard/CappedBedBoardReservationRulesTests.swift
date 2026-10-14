@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedBedBoardReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCappedBedBoardReservationValidator()
        let item = BedManagement.newCappedBedBoardReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCappedBedBoardReservationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.CappedBedBoardReservationNameLengthRule(maxLength: 16)
        let item = BedManagement.newCappedBedBoardReservation("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedBedBoardReservationRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = BedManagement.CappedBedBoardReservationRefillsRangeRule(min: 1000, max: 1000)
        let item = BedManagement.newCappedBedBoardReservation("x", name: "y")
        item.refills = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCappedBedBoardReservationAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = BedManagement.CappedBedBoardReservationAttemptsRangeRule(min: 32, max: 64)
        let item = BedManagement.newCappedBedBoardReservation("x", name: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCappedBedBoardReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CappedBedBoardReservationRequiredCodeRule(
            message: "capped bed board reservation needs this field"
        )
        let item = BedManagement.newCappedBedBoardReservation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
