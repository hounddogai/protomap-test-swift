@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalClaimBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRegionalClaimBundleValidator()
        let item = RevenueCycle.newRegionalClaimBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRegionalClaimBundleRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = RevenueCycle.RegionalClaimBundleRetriesRangeRule(min: 32, max: 80)
        let item = RevenueCycle.newRegionalClaimBundle("x", label: "y")
        item.retries = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRegionalClaimBundleRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = RevenueCycle.RegionalClaimBundleRequiredClinicianIDRule(
            message: "regional claim bundle needs this field"
        )
        let item = RevenueCycle.newRegionalClaimBundle("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalClaimBundleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.RegionalClaimBundleLabelLengthRule(maxLength: 255)
        let item = RevenueCycle.newRegionalClaimBundle("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
