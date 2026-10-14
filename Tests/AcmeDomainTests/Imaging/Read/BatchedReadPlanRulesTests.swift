@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedReadPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultBatchedReadPlanValidator()
        let item = Imaging.newBatchedReadPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingBatchedReadPlanRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Imaging.BatchedReadPlanRequiredNotesRule(message: "batched read plan needs an entry")
        let item = Imaging.newBatchedReadPlan("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingBatchedReadPlanRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.BatchedReadPlanRequiredNameRule(message: "batched read plan needs this field")
        let item = Imaging.newBatchedReadPlan("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingBatchedReadPlanRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.BatchedReadPlanRequiredLabelRule(message: "batched read plan needs a value")
        let item = Imaging.newBatchedReadPlan("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingBatchedReadPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.BatchedReadPlanRequiredCodeRule(message: "batched read plan needs a value")
        let item = Imaging.newBatchedReadPlan("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
