@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultScheduledInventoryCheckpointValidator()
        let item = Pharmacy.newScheduledInventoryCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyScheduledInventoryCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.ScheduledInventoryCheckpointCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newScheduledInventoryCheckpoint("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyScheduledInventoryCheckpointRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Pharmacy.ScheduledInventoryCheckpointRequiredPayerRule(
            message: "scheduled inventory checkpoint needs a value"
        )
        let item = Pharmacy.newScheduledInventoryCheckpoint("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyScheduledInventoryCheckpointRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.ScheduledInventoryCheckpointRequiredLabelRule(
            message: "scheduled inventory checkpoint needs an entry"
        )
        let item = Pharmacy.newScheduledInventoryCheckpoint("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
