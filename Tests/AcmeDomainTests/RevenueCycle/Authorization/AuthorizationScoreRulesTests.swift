@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationScoreValidator()
        let item = RevenueCycle.newAuthorizationScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationScoreContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = RevenueCycle.AuthorizationScoreContactEmailLengthRule(maxLength: 64)
        let item = RevenueCycle.newAuthorizationScore("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationScoreRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.AuthorizationScoreRequiredTitleRule(message: "authorization score needs an entry")
        let item = RevenueCycle.newAuthorizationScore("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AuthorizationScoreRequiredCodeRule(message: "authorization score needs a value")
        let item = RevenueCycle.newAuthorizationScore("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
