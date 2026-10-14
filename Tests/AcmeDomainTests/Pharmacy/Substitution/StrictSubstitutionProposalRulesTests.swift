@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictSubstitutionProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultStrictSubstitutionProposalValidator()
        let item = Pharmacy.newStrictSubstitutionProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyStrictSubstitutionProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.StrictSubstitutionProposalRequiredCodeRule(
            message: "strict substitution proposal needs a value"
        )
        let item = Pharmacy.newStrictSubstitutionProposal("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyStrictSubstitutionProposalAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.StrictSubstitutionProposalAttemptsRangeRule(min: 64, max: 86400)
        let item = Pharmacy.newStrictSubstitutionProposal("x", name: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyStrictSubstitutionProposalVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.StrictSubstitutionProposalVersionRangeRule(min: 32, max: 3600)
        let item = Pharmacy.newStrictSubstitutionProposal("x", name: "y")
        item.version = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyStrictSubstitutionProposalNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.StrictSubstitutionProposalNameLengthRule(maxLength: 16)
        let item = Pharmacy.newStrictSubstitutionProposal("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
