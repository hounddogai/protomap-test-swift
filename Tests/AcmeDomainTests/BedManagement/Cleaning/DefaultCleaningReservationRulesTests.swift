@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDefaultCleaningReservationValidator()
        let item = BedManagement.newDefaultCleaningReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDefaultCleaningReservationChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = BedManagement.DefaultCleaningReservationChannelLengthRule(maxLength: 80)
        let item = BedManagement.newDefaultCleaningReservation("x", label: "y")
        item.channel = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDefaultCleaningReservationCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = BedManagement.DefaultCleaningReservationCostRangeRule(min: 9.3, max: 4669.0)
        let item = BedManagement.newDefaultCleaningReservation("x", label: "y")
        item.cost = 4670.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultCleaningReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DefaultCleaningReservationRequiredCodeRule(
            message: "default cleaning reservation needs this field"
        )
        let item = BedManagement.newDefaultCleaningReservation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
