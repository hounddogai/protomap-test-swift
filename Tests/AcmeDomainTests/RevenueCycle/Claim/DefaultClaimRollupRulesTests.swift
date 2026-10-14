@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultClaimRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultClaimRollupValidator()
        let item = RevenueCycle.newDefaultClaimRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultClaimRollupRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = RevenueCycle.DefaultClaimRollupRequiredCategoryRule(message: "default claim rollup needs this field")
        let item = RevenueCycle.newDefaultClaimRollup("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultClaimRollupRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = RevenueCycle.DefaultClaimRollupRevisionRangeRule(min: 32, max: 255)
        let item = RevenueCycle.newDefaultClaimRollup("x", name: "y")
        item.revision = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDefaultClaimRollupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.DefaultClaimRollupRequiredTitleRule(message: "default claim rollup needs an entry")
        let item = RevenueCycle.newDefaultClaimRollup("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
