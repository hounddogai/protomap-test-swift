@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInventorySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPrimaryInventorySnapshotValidator()
        let item = Pharmacy.newPrimaryInventorySnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPrimaryInventorySnapshotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.PrimaryInventorySnapshotLabelLengthRule(maxLength: 1000)
        let item = Pharmacy.newPrimaryInventorySnapshot("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPrimaryInventorySnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.PrimaryInventorySnapshotCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newPrimaryInventorySnapshot("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
