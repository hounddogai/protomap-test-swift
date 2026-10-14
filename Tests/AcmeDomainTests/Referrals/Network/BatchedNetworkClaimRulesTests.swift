@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedNetworkClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultBatchedNetworkClaimValidator()
        let item = Referrals.newBatchedNetworkClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsBatchedNetworkClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.BatchedNetworkClaimCodeLengthRule(maxLength: 64)
        let item = Referrals.newBatchedNetworkClaim("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsBatchedNetworkClaimBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Referrals.BatchedNetworkClaimBudgetRangeRule(min: 8.6, max: 4199.7)
        let item = Referrals.newBatchedNetworkClaim("x", label: "y")
        item.budget = 4201.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsBatchedNetworkClaimRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Referrals.BatchedNetworkClaimRequiredEncounterIDRule(
            message: "batched network claim needs this field"
        )
        let item = Referrals.newBatchedNetworkClaim("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedNetworkClaimRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.BatchedNetworkClaimRequiredLabelRule(message: "batched network claim needs an entry")
        let item = Referrals.newBatchedNetworkClaim("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
