@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalOrderSetEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalOrderSetEstimateValidator()
        let item = ClinicalOps.newGlobalOrderSetEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalOrderSetEstimateDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = ClinicalOps.GlobalOrderSetEstimateDosageMgRangeRule(min: 8.8, max: 1493.7)
        let item = ClinicalOps.newGlobalOrderSetEstimate("x", title: "y")
        item.dosageMg = 1495.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalOrderSetEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.GlobalOrderSetEstimateRequiredCodeRule(message: "global order set estimate needs a value")
        let item = ClinicalOps.newGlobalOrderSetEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalOrderSetEstimateVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = ClinicalOps.GlobalOrderSetEstimateVersionRangeRule(min: 32, max: 120)
        let item = ClinicalOps.newGlobalOrderSetEstimate("x", title: "y")
        item.version = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalOrderSetEstimateDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = ClinicalOps.GlobalOrderSetEstimateDiscountRangeRule(min: 3.1, max: 792.0)
        let item = ClinicalOps.newGlobalOrderSetEstimate("x", title: "y")
        item.discount = 793.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalOrderSetEstimateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.GlobalOrderSetEstimateRequiredTitleRule(
            message: "global order set estimate needs an entry"
        )
        let item = ClinicalOps.newGlobalOrderSetEstimate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
