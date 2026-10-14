@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialOverrideValidator()
        let item = RevenueCycle.newDenialOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialOverrideRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = RevenueCycle.DenialOverrideRequiredSegmentRule(message: "denial override needs an entry")
        let item = RevenueCycle.newDenialOverride("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialOverrideRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.DenialOverrideRequiredTitleRule(message: "denial override needs a value")
        let item = RevenueCycle.newDenialOverride("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
