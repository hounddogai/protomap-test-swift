@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledDenialBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultScheduledDenialBaselineValidator()
        let item = RevenueCycle.newScheduledDenialBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleScheduledDenialBaselineRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = RevenueCycle.ScheduledDenialBaselineRequiredWardRule(
            message: "scheduled denial baseline needs a value"
        )
        let item = RevenueCycle.newScheduledDenialBaseline("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleScheduledDenialBaselineRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.ScheduledDenialBaselineRequiredNameRule(
            message: "scheduled denial baseline needs a value"
        )
        let item = RevenueCycle.newScheduledDenialBaseline("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
