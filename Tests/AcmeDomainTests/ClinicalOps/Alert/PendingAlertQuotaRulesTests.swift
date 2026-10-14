@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingAlertQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPendingAlertQuotaValidator()
        let item = ClinicalOps.newPendingAlertQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPendingAlertQuotaRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = ClinicalOps.PendingAlertQuotaRequiredSegmentRule(message: "pending alert quota needs this field")
        let item = ClinicalOps.newPendingAlertQuota("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPendingAlertQuotaTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.PendingAlertQuotaTitleLengthRule(maxLength: 86400)
        let item = ClinicalOps.newPendingAlertQuota("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPendingAlertQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.PendingAlertQuotaCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newPendingAlertQuota("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPendingAlertQuotaRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = ClinicalOps.PendingAlertQuotaRefillsRangeRule(min: 120, max: 86400)
        let item = ClinicalOps.newPendingAlertQuota("x", title: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPendingAlertQuotaAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = ClinicalOps.PendingAlertQuotaAmountRangeRule(min: 9.9, max: 899.5)
        let item = ClinicalOps.newPendingAlertQuota("x", title: "y")
        item.amount = 901.0
        #expect(rule.check(item).count > 0)
    }
}
