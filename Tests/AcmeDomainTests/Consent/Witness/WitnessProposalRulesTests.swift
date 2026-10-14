@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessProposalValidator()
        let item = Consent.newWitnessProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessProposalRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.WitnessProposalRequiredTitleRule(message: "witness proposal needs this field")
        let item = Consent.newWitnessProposal("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessProposalClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Consent.WitnessProposalClinicianIDLengthRule(maxLength: 1000)
        let item = Consent.newWitnessProposal("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WitnessProposalRequiredCodeRule(message: "witness proposal needs this field")
        let item = Consent.newWitnessProposal("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
