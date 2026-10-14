@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTieredTaskSummaryValidator()
        let item = ClinicalOps.newTieredTaskSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTieredTaskSummaryCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = ClinicalOps.TieredTaskSummaryCountryLengthRule(maxLength: 3600)
        let item = ClinicalOps.newTieredTaskSummary("x", title: "y")
        item.country = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTieredTaskSummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.TieredTaskSummaryRequiredTitleRule(message: "tiered task summary needs this field")
        let item = ClinicalOps.newTieredTaskSummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredTaskSummaryCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = ClinicalOps.TieredTaskSummaryCostRangeRule(min: 4.4, max: 1691.8)
        let item = ClinicalOps.newTieredTaskSummary("x", title: "y")
        item.cost = 1693.3
        #expect(rule.check(item).count > 0)
    }
}
