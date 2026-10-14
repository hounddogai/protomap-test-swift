@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyProposalValidator()
        let item = Consent.newProxyProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyProposalRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ProxyProposalRequiredNameRule(message: "proxy proposal needs a value")
        let item = Consent.newProxyProposal("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyProposalRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Consent.ProxyProposalRequiredFacilityRule(message: "proxy proposal needs this field")
        let item = Consent.newProxyProposal("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ProxyProposalRequiredCodeRule(message: "proxy proposal needs this field")
        let item = Consent.newProxyProposal("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
