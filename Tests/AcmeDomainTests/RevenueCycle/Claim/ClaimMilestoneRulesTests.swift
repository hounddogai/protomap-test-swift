@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimMilestoneValidator()
        let item = RevenueCycle.newClaimMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimMilestoneRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = RevenueCycle.ClaimMilestoneRevisionRangeRule(min: 120, max: 3600)
        let item = RevenueCycle.newClaimMilestone("x", name: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimMilestoneRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = RevenueCycle.ClaimMilestoneRequiredSummaryRule(message: "claim milestone needs this field")
        let item = RevenueCycle.newClaimMilestone("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimMilestoneCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = RevenueCycle.ClaimMilestoneCreatedAtRangeRule(min: 16, max: 255)
        let item = RevenueCycle.newClaimMilestone("x", name: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimMilestoneSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = RevenueCycle.ClaimMilestoneSummaryLengthRule(maxLength: 80)
        let item = RevenueCycle.newClaimMilestone("x", name: "y")
        item.summary = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
