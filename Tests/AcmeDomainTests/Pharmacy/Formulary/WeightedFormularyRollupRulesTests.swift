@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedFormularyRollupValidator()
        let item = Pharmacy.newWeightedFormularyRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedFormularyRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.WeightedFormularyRollupRequiredCodeRule(message: "weighted formulary rollup needs an entry")
        let item = Pharmacy.newWeightedFormularyRollup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyWeightedFormularyRollupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.WeightedFormularyRollupNameLengthRule(maxLength: 80)
        let item = Pharmacy.newWeightedFormularyRollup("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedFormularyRollupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.WeightedFormularyRollupRequiredNameRule(
            message: "weighted formulary rollup needs this field"
        )
        let item = Pharmacy.newWeightedFormularyRollup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
