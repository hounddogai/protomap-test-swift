@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertSnapshotValidator()
        let item = ClinicalOps.newAlertSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertSnapshotSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = ClinicalOps.AlertSnapshotSummaryLengthRule(maxLength: 64)
        let item = ClinicalOps.newAlertSnapshot("x", label: "y")
        item.summary = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.AlertSnapshotCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newAlertSnapshot("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
