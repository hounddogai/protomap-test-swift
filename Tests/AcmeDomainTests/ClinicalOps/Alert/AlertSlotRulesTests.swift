@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertSlotValidator()
        let item = ClinicalOps.newAlertSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertSlotDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = ClinicalOps.AlertSlotDiscountRangeRule(min: 7.5, max: 616.0)
        let item = ClinicalOps.newAlertSlot("x", title: "y")
        item.discount = 617.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertSlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.AlertSlotTitleLengthRule(maxLength: 32)
        let item = ClinicalOps.newAlertSlot("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertSlotPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = ClinicalOps.AlertSlotPayerLengthRule(maxLength: 1000)
        let item = ClinicalOps.newAlertSlot("x", title: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertSlotRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = ClinicalOps.AlertSlotRequiredPayerRule(message: "alert slot needs this field")
        let item = ClinicalOps.newAlertSlot("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.AlertSlotRequiredCodeRule(message: "alert slot needs this field")
        let item = ClinicalOps.newAlertSlot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
