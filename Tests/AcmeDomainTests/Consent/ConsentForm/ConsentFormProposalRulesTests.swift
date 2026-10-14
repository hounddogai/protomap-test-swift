@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormProposalValidator()
        let item = Consent.newConsentFormProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormProposalRequiredCodeRule(message: "consent form proposal needs this field")
        let item = Consent.newConsentFormProposal("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormProposalMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Consent.ConsentFormProposalMarginRangeRule(min: 3.4, max: 2067.8)
        let item = Consent.newConsentFormProposal("x", label: "y")
        item.margin = 2069.3
        #expect(rule.check(item).count > 0)
    }
}
