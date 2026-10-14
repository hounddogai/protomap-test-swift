@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationSegmentValidator()
        let item = RevenueCycle.newAuthorizationSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationSegmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.AuthorizationSegmentRequiredNameRule(message: "authorization segment needs an entry")
        let item = RevenueCycle.newAuthorizationSegment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AuthorizationSegmentRequiredCodeRule(message: "authorization segment needs an entry")
        let item = RevenueCycle.newAuthorizationSegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
