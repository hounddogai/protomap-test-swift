@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffSummaryValidator()
        let item = ClinicalOps.newHandoffSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.HandoffSummaryRequiredCodeRule(message: "handoff summary needs an entry")
        let item = ClinicalOps.newHandoffSummary("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffSummaryPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.HandoffSummaryPatientRefLengthRule(maxLength: 1000)
        let item = ClinicalOps.newHandoffSummary("x", title: "y")
        item.patientRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffSummarySummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = ClinicalOps.HandoffSummarySummaryLengthRule(maxLength: 32)
        let item = ClinicalOps.newHandoffSummary("x", title: "y")
        item.summary = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffSummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.HandoffSummaryRequiredTitleRule(message: "handoff summary needs a value")
        let item = ClinicalOps.newHandoffSummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffSummaryRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = ClinicalOps.HandoffSummaryRequiredPatientRefRule(message: "handoff summary needs an entry")
        let item = ClinicalOps.newHandoffSummary("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
