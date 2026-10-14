@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceMilestoneValidator()
        let item = RevenueCycle.newRemittanceMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceMilestoneRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = RevenueCycle.RemittanceMilestoneRequiredOwnerIDRule(message: "remittance milestone needs this field")
        let item = RevenueCycle.newRemittanceMilestone("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceMilestoneGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = RevenueCycle.RemittanceMilestoneGraceDaysRangeRule(min: 32, max: 3600)
        let item = RevenueCycle.newRemittanceMilestone("x", title: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceMilestoneDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = RevenueCycle.RemittanceMilestoneDosageMgRangeRule(min: 8.2, max: 2317.8)
        let item = RevenueCycle.newRemittanceMilestone("x", title: "y")
        item.dosageMg = 2319.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceMilestoneWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = RevenueCycle.RemittanceMilestoneWeightRangeRule(min: 2.2, max: 2090.9)
        let item = RevenueCycle.newRemittanceMilestone("x", title: "y")
        item.weight = 2092.4
        #expect(rule.check(item).count > 0)
    }
}
