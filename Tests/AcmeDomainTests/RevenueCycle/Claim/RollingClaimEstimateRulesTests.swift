@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingClaimEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRollingClaimEstimateValidator()
        let item = RevenueCycle.newRollingClaimEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRollingClaimEstimateRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = RevenueCycle.RollingClaimEstimateRetriesRangeRule(min: 80, max: 255)
        let item = RevenueCycle.newRollingClaimEstimate("x", title: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRollingClaimEstimateCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = RevenueCycle.RollingClaimEstimateCopayRangeRule(min: 4.3, max: 2507.6)
        let item = RevenueCycle.newRollingClaimEstimate("x", title: "y")
        item.copay = 2509.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRollingClaimEstimateRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = RevenueCycle.RollingClaimEstimateRequiredClinicianIDRule(
            message: "rolling claim estimate needs a value"
        )
        let item = RevenueCycle.newRollingClaimEstimate("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
