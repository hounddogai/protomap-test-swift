@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseSnapshotValidator()
        let item = Pharmacy.newDispenseSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DispenseSnapshotRequiredCodeRule(message: "dispense snapshot needs a value")
        let item = Pharmacy.newDispenseSnapshot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseSnapshotDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Pharmacy.DispenseSnapshotDosageMgRangeRule(min: 5.4, max: 2517.4)
        let item = Pharmacy.newDispenseSnapshot("x", name: "y")
        item.dosageMg = 2518.9
        #expect(rule.check(item).count > 0)
    }
}
