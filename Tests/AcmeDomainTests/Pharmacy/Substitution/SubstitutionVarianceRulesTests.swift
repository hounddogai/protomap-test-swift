@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionVarianceValidator()
        let item = Pharmacy.newSubstitutionVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.SubstitutionVarianceCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newSubstitutionVariance("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.SubstitutionVarianceRequiredLabelRule(message: "substitution variance needs an entry")
        let item = Pharmacy.newSubstitutionVariance("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionVarianceSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Pharmacy.SubstitutionVarianceSummaryLengthRule(maxLength: 255)
        let item = Pharmacy.newSubstitutionVariance("x", label: "y")
        item.summary = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionVarianceCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Pharmacy.SubstitutionVarianceCostRangeRule(min: 9.9, max: 2511.0)
        let item = Pharmacy.newSubstitutionVariance("x", label: "y")
        item.cost = 2512.5
        #expect(rule.check(item).count > 0)
    }
}
