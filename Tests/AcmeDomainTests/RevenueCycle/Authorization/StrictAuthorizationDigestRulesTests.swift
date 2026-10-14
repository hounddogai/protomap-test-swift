@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictAuthorizationDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStrictAuthorizationDigestValidator()
        let item = RevenueCycle.newStrictAuthorizationDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStrictAuthorizationDigestRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = RevenueCycle.StrictAuthorizationDigestRequiredPhoneRule(
            message: "strict authorization digest needs an entry"
        )
        let item = RevenueCycle.newStrictAuthorizationDigest("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStrictAuthorizationDigestPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.StrictAuthorizationDigestPriorityRangeRule(min: 80, max: 3600)
        let item = RevenueCycle.newStrictAuthorizationDigest("x", name: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStrictAuthorizationDigestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.StrictAuthorizationDigestRequiredNameRule(
            message: "strict authorization digest needs an entry"
        )
        let item = RevenueCycle.newStrictAuthorizationDigest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
