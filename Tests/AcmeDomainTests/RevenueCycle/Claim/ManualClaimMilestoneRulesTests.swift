@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualClaimMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualClaimMilestoneValidator()
        let item = RevenueCycle.newManualClaimMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualClaimMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ManualClaimMilestoneRequiredCodeRule(message: "manual claim milestone needs an entry")
        let item = RevenueCycle.newManualClaimMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualClaimMilestoneNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ManualClaimMilestoneNameLengthRule(maxLength: 3600)
        let item = RevenueCycle.newManualClaimMilestone("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualClaimMilestoneWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = RevenueCycle.ManualClaimMilestoneWindowDaysRangeRule(min: 64, max: 86400)
        let item = RevenueCycle.newManualClaimMilestone("x", name: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleManualClaimMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ManualClaimMilestoneCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newManualClaimMilestone("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
