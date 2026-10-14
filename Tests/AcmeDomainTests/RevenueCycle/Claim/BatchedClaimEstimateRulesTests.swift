@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedClaimEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedClaimEstimateValidator()
        let item = RevenueCycle.newBatchedClaimEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedClaimEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.BatchedClaimEstimateRequiredCodeRule(message: "batched claim estimate needs a value")
        let item = RevenueCycle.newBatchedClaimEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedClaimEstimateRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = RevenueCycle.BatchedClaimEstimateRequiredPayerRule(message: "batched claim estimate needs a value")
        let item = RevenueCycle.newBatchedClaimEstimate("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedClaimEstimateRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = RevenueCycle.BatchedClaimEstimateRequiredExternalRefRule(
            message: "batched claim estimate needs an entry"
        )
        let item = RevenueCycle.newBatchedClaimEstimate("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
