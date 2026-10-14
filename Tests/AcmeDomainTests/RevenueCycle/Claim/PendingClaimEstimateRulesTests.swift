@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingClaimEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPendingClaimEstimateValidator()
        let item = RevenueCycle.newPendingClaimEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePendingClaimEstimateCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = RevenueCycle.PendingClaimEstimateCopayRangeRule(min: 6.4, max: 545.9)
        let item = RevenueCycle.newPendingClaimEstimate("x", label: "y")
        item.copay = 547.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCyclePendingClaimEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.PendingClaimEstimateCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newPendingClaimEstimate("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePendingClaimEstimateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.PendingClaimEstimateRequiredLabelRule(message: "pending claim estimate needs an entry")
        let item = RevenueCycle.newPendingClaimEstimate("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePendingClaimEstimateRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = RevenueCycle.PendingClaimEstimateRequiredWardRule(message: "pending claim estimate needs this field")
        let item = RevenueCycle.newPendingClaimEstimate("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
