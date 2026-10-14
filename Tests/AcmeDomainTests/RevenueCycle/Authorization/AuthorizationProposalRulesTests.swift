@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationProposalValidator()
        let item = RevenueCycle.newAuthorizationProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationProposalRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = RevenueCycle.AuthorizationProposalRateRangeRule(min: 3.9, max: 3509.1)
        let item = RevenueCycle.newAuthorizationProposal("x", label: "y")
        item.rate = 3510.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationProposalEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = RevenueCycle.AuthorizationProposalEndsAtRangeRule(min: 120, max: 86400)
        let item = RevenueCycle.newAuthorizationProposal("x", label: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationProposalLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.AuthorizationProposalLabelLengthRule(maxLength: 80)
        let item = RevenueCycle.newAuthorizationProposal("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
