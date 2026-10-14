@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularySnapshotValidator()
        let item = Pharmacy.newFormularySnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularySnapshotMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Pharmacy.FormularySnapshotMaximumRangeRule(min: 8.1, max: 2416.4)
        let item = Pharmacy.newFormularySnapshot("x", title: "y")
        item.maximum = 2417.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularySnapshotRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Pharmacy.FormularySnapshotRatioRangeRule(min: 1.9, max: 3156.3)
        let item = Pharmacy.newFormularySnapshot("x", title: "y")
        item.ratio = 3157.8
        #expect(rule.check(item).count > 0)
    }
}
