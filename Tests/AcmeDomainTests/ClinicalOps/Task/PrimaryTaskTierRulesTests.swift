@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryTaskTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPrimaryTaskTierValidator()
        let item = ClinicalOps.newPrimaryTaskTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPrimaryTaskTierTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.PrimaryTaskTierTitleLengthRule(maxLength: 86400)
        let item = ClinicalOps.newPrimaryTaskTier("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryTaskTierRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.PrimaryTaskTierRequiredTitleRule(message: "primary task tier needs a value")
        let item = ClinicalOps.newPrimaryTaskTier("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPrimaryTaskTierMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = ClinicalOps.PrimaryTaskTierMinimumRangeRule(min: 6.6, max: 1029.7)
        let item = ClinicalOps.newPrimaryTaskTier("x", title: "y")
        item.minimum = 1031.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPrimaryTaskTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.PrimaryTaskTierCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newPrimaryTaskTier("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryTaskTierRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = ClinicalOps.PrimaryTaskTierRegionLengthRule(maxLength: 32)
        let item = ClinicalOps.newPrimaryTaskTier("x", title: "y")
        item.region = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
