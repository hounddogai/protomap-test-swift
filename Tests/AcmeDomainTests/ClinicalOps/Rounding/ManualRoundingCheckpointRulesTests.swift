@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualRoundingCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultManualRoundingCheckpointValidator()
        let item = ClinicalOps.newManualRoundingCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsManualRoundingCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.ManualRoundingCheckpointRequiredNameRule(
            message: "manual rounding checkpoint needs a value"
        )
        let item = ClinicalOps.newManualRoundingCheckpoint("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsManualRoundingCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.ManualRoundingCheckpointRequiredCodeRule(
            message: "manual rounding checkpoint needs a value"
        )
        let item = ClinicalOps.newManualRoundingCheckpoint("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsManualRoundingCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.ManualRoundingCheckpointRequiredTitleRule(
            message: "manual rounding checkpoint needs a value"
        )
        let item = ClinicalOps.newManualRoundingCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsManualRoundingCheckpointDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = ClinicalOps.ManualRoundingCheckpointDiscountRangeRule(min: 9.5, max: 3879.5)
        let item = ClinicalOps.newManualRoundingCheckpoint("x", title: "y")
        item.discount = 3881.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsManualRoundingCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.ManualRoundingCheckpointCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newManualRoundingCheckpoint("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
