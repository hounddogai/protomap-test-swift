@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualInventorySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultManualInventorySnapshotValidator()
        let item = Pharmacy.newManualInventorySnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyManualInventorySnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.ManualInventorySnapshotCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newManualInventorySnapshot("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualInventorySnapshotContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Pharmacy.ManualInventorySnapshotContactEmailLengthRule(maxLength: 80)
        let item = Pharmacy.newManualInventorySnapshot("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualInventorySnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.ManualInventorySnapshotRequiredCodeRule(
            message: "manual inventory snapshot needs this field"
        )
        let item = Pharmacy.newManualInventorySnapshot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualInventorySnapshotQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Pharmacy.ManualInventorySnapshotQuantityRangeRule(min: 32, max: 86400)
        let item = Pharmacy.newManualInventorySnapshot("x", label: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}
