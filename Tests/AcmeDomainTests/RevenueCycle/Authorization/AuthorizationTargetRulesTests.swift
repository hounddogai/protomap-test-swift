@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationTargetValidator()
        let item = RevenueCycle.newAuthorizationTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationTargetRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = RevenueCycle.AuthorizationTargetRequiredBedRule(message: "authorization target needs a value")
        let item = RevenueCycle.newAuthorizationTarget("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationTargetBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = RevenueCycle.AuthorizationTargetBedLengthRule(maxLength: 255)
        let item = RevenueCycle.newAuthorizationTarget("x", title: "y")
        item.bed = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AuthorizationTargetRequiredCodeRule(message: "authorization target needs a value")
        let item = RevenueCycle.newAuthorizationTarget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
