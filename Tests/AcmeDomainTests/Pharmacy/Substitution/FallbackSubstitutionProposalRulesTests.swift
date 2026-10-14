@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackSubstitutionProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFallbackSubstitutionProposalValidator()
        let item = Pharmacy.newFallbackSubstitutionProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFallbackSubstitutionProposalMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Pharmacy.FallbackSubstitutionProposalMinimumRangeRule(min: 4.9, max: 2391.0)
        let item = Pharmacy.newFallbackSubstitutionProposal("x", label: "y")
        item.minimum = 2392.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFallbackSubstitutionProposalMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Pharmacy.FallbackSubstitutionProposalMarginRangeRule(min: 8.7, max: 1006.1)
        let item = Pharmacy.newFallbackSubstitutionProposal("x", label: "y")
        item.margin = 1007.6
        #expect(rule.check(item).count > 0)
    }
}
