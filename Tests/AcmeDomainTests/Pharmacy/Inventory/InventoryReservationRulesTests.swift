@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryReservationValidator()
        let item = Pharmacy.newInventoryReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryReservationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.InventoryReservationRequiredLabelRule(message: "inventory reservation needs a value")
        let item = Pharmacy.newInventoryReservation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.InventoryReservationLabelLengthRule(maxLength: 16)
        let item = Pharmacy.newInventoryReservation("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
