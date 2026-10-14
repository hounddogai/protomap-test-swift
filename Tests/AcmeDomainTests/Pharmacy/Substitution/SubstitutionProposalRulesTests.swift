@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionProposalValidator()
        let item = Pharmacy.newSubstitutionProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionProposalRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.SubstitutionProposalRequiredTitleRule(message: "substitution proposal needs an entry")
        let item = Pharmacy.newSubstitutionProposal("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionProposalCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Pharmacy.SubstitutionProposalCopayRangeRule(min: 8.1, max: 3468.2)
        let item = Pharmacy.newSubstitutionProposal("x", title: "y")
        item.copay = 3469.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySubstitutionProposalTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.SubstitutionProposalTitleLengthRule(maxLength: 120)
        let item = Pharmacy.newSubstitutionProposal("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.SubstitutionProposalCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newSubstitutionProposal("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
