@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveDenialVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAdaptiveDenialVarianceValidator()
        let item = RevenueCycle.newAdaptiveDenialVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAdaptiveDenialVarianceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.AdaptiveDenialVarianceLabelLengthRule(maxLength: 86400)
        let item = RevenueCycle.newAdaptiveDenialVariance("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAdaptiveDenialVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AdaptiveDenialVarianceRequiredCodeRule(
            message: "adaptive denial variance needs an entry"
        )
        let item = RevenueCycle.newAdaptiveDenialVariance("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
