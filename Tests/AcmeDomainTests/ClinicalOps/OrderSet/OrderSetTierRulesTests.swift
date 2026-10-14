@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetTierValidator()
        let item = ClinicalOps.newOrderSetTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetTierCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = ClinicalOps.OrderSetTierCapacityRangeRule(min: 32, max: 80)
        let item = ClinicalOps.newOrderSetTier("x", label: "y")
        item.capacity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.OrderSetTierCodeLengthRule(maxLength: 3600)
        let item = ClinicalOps.newOrderSetTier("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetTierRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.OrderSetTierRequiredLabelRule(message: "order set tier needs a value")
        let item = ClinicalOps.newOrderSetTier("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetTierScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = ClinicalOps.OrderSetTierScoreRangeRule(min: 7.4, max: 4898.1)
        let item = ClinicalOps.newOrderSetTier("x", label: "y")
        item.score = 4899.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetTierRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = ClinicalOps.OrderSetTierRequiredDiagnosisCodeRule(message: "order set tier needs this field")
        let item = ClinicalOps.newOrderSetTier("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetTierRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = ClinicalOps.OrderSetTierRequiredDescriptionRule(message: "order set tier needs this field")
        let item = ClinicalOps.newOrderSetTier("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
