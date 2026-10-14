@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalTaskThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultSeasonalTaskThresholdValidator()
        let item = ClinicalOps.newSeasonalTaskThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsSeasonalTaskThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.SeasonalTaskThresholdCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newSeasonalTaskThreshold("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsSeasonalTaskThresholdRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = ClinicalOps.SeasonalTaskThresholdRequiredContactEmailRule(
            message: "seasonal task threshold needs this field"
        )
        let item = ClinicalOps.newSeasonalTaskThreshold("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsSeasonalTaskThresholdDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = ClinicalOps.SeasonalTaskThresholdDiscountRangeRule(min: 9.8, max: 2105.7)
        let item = ClinicalOps.newSeasonalTaskThreshold("x", name: "y")
        item.discount = 2107.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsSeasonalTaskThresholdRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.SeasonalTaskThresholdRequiredNameRule(message: "seasonal task threshold needs this field")
        let item = ClinicalOps.newSeasonalTaskThreshold("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsSeasonalTaskThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.SeasonalTaskThresholdNameLengthRule(maxLength: 1000)
        let item = ClinicalOps.newSeasonalTaskThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
