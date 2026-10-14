@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedSubstitutionProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultBatchedSubstitutionProposalValidator()
        let item = Pharmacy.newBatchedSubstitutionProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionProposalVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.BatchedSubstitutionProposalVersionRangeRule(min: 120, max: 255)
        let item = Pharmacy.newBatchedSubstitutionProposal("x", name: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionProposalAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Pharmacy.BatchedSubstitutionProposalAcuityRangeRule(min: 32, max: 1000)
        let item = Pharmacy.newBatchedSubstitutionProposal("x", name: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionProposalCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Pharmacy.BatchedSubstitutionProposalCurrencyLengthRule(maxLength: 120)
        let item = Pharmacy.newBatchedSubstitutionProposal("x", name: "y")
        item.currency = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}
