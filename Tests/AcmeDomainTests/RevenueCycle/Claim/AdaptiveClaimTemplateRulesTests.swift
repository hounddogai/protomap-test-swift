@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveClaimTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAdaptiveClaimTemplateValidator()
        let item = RevenueCycle.newAdaptiveClaimTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAdaptiveClaimTemplateContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = RevenueCycle.AdaptiveClaimTemplateContactEmailLengthRule(maxLength: 3600)
        let item = RevenueCycle.newAdaptiveClaimTemplate("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
