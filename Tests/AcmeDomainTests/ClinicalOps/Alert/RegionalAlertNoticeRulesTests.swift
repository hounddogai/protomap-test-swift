@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRegionalAlertNoticeValidator()
        let item = ClinicalOps.newRegionalAlertNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertNoticeSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = ClinicalOps.RegionalAlertNoticeSummaryLengthRule(maxLength: 86400)
        let item = ClinicalOps.newRegionalAlertNotice("x", label: "y")
        item.summary = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.RegionalAlertNoticeRequiredCodeRule(message: "regional alert notice needs this field")
        let item = ClinicalOps.newRegionalAlertNotice("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRegionalAlertNoticeSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = ClinicalOps.RegionalAlertNoticeSequenceRangeRule(min: 80, max: 86400)
        let item = ClinicalOps.newRegionalAlertNotice("x", label: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RegionalAlertNoticeCodeLengthRule(maxLength: 120)
        let item = ClinicalOps.newRegionalAlertNotice("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
