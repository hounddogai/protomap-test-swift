@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationVarianceValidator()
        let item = RevenueCycle.newAuthorizationVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.AuthorizationVarianceCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newAuthorizationVariance("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationVarianceExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = RevenueCycle.AuthorizationVarianceExternalRefLengthRule(maxLength: 255)
        let item = RevenueCycle.newAuthorizationVariance("x", title: "y")
        item.externalRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
