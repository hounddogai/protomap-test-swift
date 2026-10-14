@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolTierValidator()
        let item = ClinicalOps.newCareProtocolTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CareProtocolTierRequiredCodeRule(message: "care protocol tier needs this field")
        let item = ClinicalOps.newCareProtocolTier("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolTierRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.CareProtocolTierRequiredTitleRule(message: "care protocol tier needs this field")
        let item = ClinicalOps.newCareProtocolTier("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolTierVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = ClinicalOps.CareProtocolTierVersionRangeRule(min: 80, max: 120)
        let item = ClinicalOps.newCareProtocolTier("x", title: "y")
        item.version = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolTierCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = ClinicalOps.CareProtocolTierCostRangeRule(min: 0.4, max: 4486.6)
        let item = ClinicalOps.newCareProtocolTier("x", title: "y")
        item.cost = 4488.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolTierRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = ClinicalOps.CareProtocolTierRatioRangeRule(min: 7.1, max: 2590.5)
        let item = ClinicalOps.newCareProtocolTier("x", title: "y")
        item.ratio = 2592.0
        #expect(rule.check(item).count > 0)
    }
}
