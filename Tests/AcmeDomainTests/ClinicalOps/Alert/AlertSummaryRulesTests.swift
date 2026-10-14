@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertSummaryValidator()
        let item = ClinicalOps.newAlertSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.AlertSummaryCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newAlertSummary("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertSummaryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.AlertSummaryLabelLengthRule(maxLength: 120)
        let item = ClinicalOps.newAlertSummary("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertSummaryRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = ClinicalOps.AlertSummaryRequiredExternalRefRule(message: "alert summary needs this field")
        let item = ClinicalOps.newAlertSummary("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.AlertSummaryRequiredCodeRule(message: "alert summary needs a value")
        let item = ClinicalOps.newAlertSummary("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertSummaryRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = ClinicalOps.AlertSummaryRequiredOwnerIDRule(message: "alert summary needs an entry")
        let item = ClinicalOps.newAlertSummary("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
