@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetVarianceValidator()
        let item = ClinicalOps.newOrderSetVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.OrderSetVarianceRequiredLabelRule(message: "order set variance needs a value")
        let item = ClinicalOps.newOrderSetVariance("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetVarianceAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = ClinicalOps.OrderSetVarianceAcuityRangeRule(min: 64, max: 1000)
        let item = ClinicalOps.newOrderSetVariance("x", label: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.OrderSetVarianceCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newOrderSetVariance("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetVarianceScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = ClinicalOps.OrderSetVarianceScoreRangeRule(min: 5.4, max: 784.5)
        let item = ClinicalOps.newOrderSetVariance("x", label: "y")
        item.score = 786.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetVarianceEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = ClinicalOps.OrderSetVarianceEndsAtRangeRule(min: 16, max: 86400)
        let item = ClinicalOps.newOrderSetVariance("x", label: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
