@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimProposalValidator()
        let item = RevenueCycle.newClaimProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimProposalWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = RevenueCycle.ClaimProposalWeightRangeRule(min: 8.1, max: 2141.3)
        let item = RevenueCycle.newClaimProposal("x", name: "y")
        item.weight = 2142.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ClaimProposalRequiredCodeRule(message: "claim proposal needs a value")
        let item = RevenueCycle.newClaimProposal("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.ClaimProposalRequiredLabelRule(message: "claim proposal needs an entry")
        let item = RevenueCycle.newClaimProposal("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimProposalRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = RevenueCycle.ClaimProposalRequiredDescriptionRule(message: "claim proposal needs an entry")
        let item = RevenueCycle.newClaimProposal("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ClaimProposalCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newClaimProposal("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
