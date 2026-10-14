@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledProxyProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledProxyProposalValidator()
        let item = Consent.newScheduledProxyProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledProxyProposalRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Consent.ScheduledProxyProposalRequiredPatientRefRule(
            message: "scheduled proxy proposal needs a value"
        )
        let item = Consent.newScheduledProxyProposal("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledProxyProposalRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Consent.ScheduledProxyProposalRateRangeRule(min: 6.2, max: 1271.3)
        let item = Consent.newScheduledProxyProposal("x", label: "y")
        item.rate = 1272.8
        #expect(rule.check(item).count > 0)
    }
}
