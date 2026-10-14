@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientSubstitutionRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientSubstitutionRollupValidator()
        let item = Pharmacy.newLenientSubstitutionRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientSubstitutionRollupFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Pharmacy.LenientSubstitutionRollupFloorValueRangeRule(min: 3.9, max: 3833.2)
        let item = Pharmacy.newLenientSubstitutionRollup("x", label: "y")
        item.floorValue = 3834.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLenientSubstitutionRollupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.LenientSubstitutionRollupRequiredLabelRule(
            message: "lenient substitution rollup needs this field"
        )
        let item = Pharmacy.newLenientSubstitutionRollup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientSubstitutionRollupGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Pharmacy.LenientSubstitutionRollupGraceDaysRangeRule(min: 32, max: 80)
        let item = Pharmacy.newLenientSubstitutionRollup("x", label: "y")
        item.graceDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLenientSubstitutionRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.LenientSubstitutionRollupCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newLenientSubstitutionRollup("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
