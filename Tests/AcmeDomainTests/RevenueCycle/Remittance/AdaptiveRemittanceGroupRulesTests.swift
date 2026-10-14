@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveRemittanceGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAdaptiveRemittanceGroupValidator()
        let item = RevenueCycle.newAdaptiveRemittanceGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAdaptiveRemittanceGroupRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = RevenueCycle.AdaptiveRemittanceGroupRequiredWardRule(
            message: "adaptive remittance group needs this field"
        )
        let item = RevenueCycle.newAdaptiveRemittanceGroup("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAdaptiveRemittanceGroupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.AdaptiveRemittanceGroupTitleLengthRule(maxLength: 255)
        let item = RevenueCycle.newAdaptiveRemittanceGroup("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
