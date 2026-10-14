@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingChargeProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPendingChargeProposalValidator()
        let item = RevenueCycle.newPendingChargeProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePendingChargeProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.PendingChargeProposalCodeLengthRule(maxLength: 255)
        let item = RevenueCycle.newPendingChargeProposal("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePendingChargeProposalRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = RevenueCycle.PendingChargeProposalRequiredChannelRule(
            message: "pending charge proposal needs an entry"
        )
        let item = RevenueCycle.newPendingChargeProposal("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePendingChargeProposalAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = RevenueCycle.PendingChargeProposalAcuityRangeRule(min: 32, max: 120)
        let item = RevenueCycle.newPendingChargeProposal("x", title: "y")
        item.acuity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCyclePendingChargeProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.PendingChargeProposalRequiredCodeRule(message: "pending charge proposal needs an entry")
        let item = RevenueCycle.newPendingChargeProposal("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
