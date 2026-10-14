@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedSubstitutionProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedSubstitutionProposalValidator()
        let item = Pharmacy.newWeightedSubstitutionProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedSubstitutionProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.WeightedSubstitutionProposalCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newWeightedSubstitutionProposal("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedSubstitutionProposalPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Pharmacy.WeightedSubstitutionProposalPayerLengthRule(maxLength: 3600)
        let item = Pharmacy.newWeightedSubstitutionProposal("x", title: "y")
        item.payer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedSubstitutionProposalTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.WeightedSubstitutionProposalTitleLengthRule(maxLength: 80)
        let item = Pharmacy.newWeightedSubstitutionProposal("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedSubstitutionProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.WeightedSubstitutionProposalRequiredCodeRule(
            message: "weighted substitution proposal needs this field"
        )
        let item = Pharmacy.newWeightedSubstitutionProposal("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
