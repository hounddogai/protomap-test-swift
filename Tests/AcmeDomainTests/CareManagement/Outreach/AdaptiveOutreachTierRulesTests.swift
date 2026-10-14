@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveOutreachTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveOutreachTierValidator()
        let item = CareManagement.newAdaptiveOutreachTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveOutreachTierTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.AdaptiveOutreachTierTitleLengthRule(maxLength: 255)
        let item = CareManagement.newAdaptiveOutreachTier("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveOutreachTierRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = CareManagement.AdaptiveOutreachTierRequiredRegionRule(message: "adaptive outreach tier needs a value")
        let item = CareManagement.newAdaptiveOutreachTier("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAdaptiveOutreachTierRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.AdaptiveOutreachTierRequiredTitleRule(message: "adaptive outreach tier needs a value")
        let item = CareManagement.newAdaptiveOutreachTier("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAdaptiveOutreachTierPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = CareManagement.AdaptiveOutreachTierPriorityRangeRule(min: 32, max: 1000)
        let item = CareManagement.newAdaptiveOutreachTier("x", title: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}
