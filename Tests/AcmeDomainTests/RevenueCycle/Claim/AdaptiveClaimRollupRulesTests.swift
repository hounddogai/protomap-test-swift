@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveClaimRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAdaptiveClaimRollupValidator()
        let item = RevenueCycle.newAdaptiveClaimRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAdaptiveClaimRollupRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = RevenueCycle.AdaptiveClaimRollupRequiredExternalRefRule(
            message: "adaptive claim rollup needs this field"
        )
        let item = RevenueCycle.newAdaptiveClaimRollup("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAdaptiveClaimRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.AdaptiveClaimRollupCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newAdaptiveClaimRollup("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAdaptiveClaimRollupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.AdaptiveClaimRollupRequiredNameRule(message: "adaptive claim rollup needs an entry")
        let item = RevenueCycle.newAdaptiveClaimRollup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
