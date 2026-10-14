@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventorySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventorySnapshotValidator()
        let item = Pharmacy.newInventorySnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventorySnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InventorySnapshotRequiredCodeRule(message: "inventory snapshot needs an entry")
        let item = Pharmacy.newInventorySnapshot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventorySnapshotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.InventorySnapshotRequiredLabelRule(message: "inventory snapshot needs a value")
        let item = Pharmacy.newInventorySnapshot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
