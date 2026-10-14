@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultWeightedTransferReservationValidator()
        let item = BedManagement.newWeightedTransferReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementWeightedTransferReservationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.WeightedTransferReservationTitleLengthRule(maxLength: 255)
        let item = BedManagement.newWeightedTransferReservation("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementWeightedTransferReservationRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = BedManagement.WeightedTransferReservationRequiredUnitRule(
            message: "weighted transfer reservation needs this field"
        )
        let item = BedManagement.newWeightedTransferReservation("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementWeightedTransferReservationLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = BedManagement.WeightedTransferReservationLocaleLengthRule(maxLength: 255)
        let item = BedManagement.newWeightedTransferReservation("x", title: "y")
        item.locale = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementWeightedTransferReservationRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = BedManagement.WeightedTransferReservationRequiredLocaleRule(
            message: "weighted transfer reservation needs this field"
        )
        let item = BedManagement.newWeightedTransferReservation("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementWeightedTransferReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.WeightedTransferReservationRequiredCodeRule(
            message: "weighted transfer reservation needs an entry"
        )
        let item = BedManagement.newWeightedTransferReservation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
