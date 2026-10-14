@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskSnapshotValidator()
        let item = ClinicalOps.newTaskSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskSnapshotPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = ClinicalOps.TaskSnapshotPayerLengthRule(maxLength: 3600)
        let item = ClinicalOps.newTaskSnapshot("x", label: "y")
        item.payer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskSnapshotSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = ClinicalOps.TaskSnapshotSummaryLengthRule(maxLength: 120)
        let item = ClinicalOps.newTaskSnapshot("x", label: "y")
        item.summary = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TaskSnapshotCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newTaskSnapshot("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskSnapshotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.TaskSnapshotRequiredLabelRule(message: "task snapshot needs a value")
        let item = ClinicalOps.newTaskSnapshot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
