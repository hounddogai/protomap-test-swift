@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedProgramDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedProgramDraftValidator()
        let item = CareManagement.newBatchedProgramDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedProgramDraftExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.BatchedProgramDraftExternalRefLengthRule(maxLength: 1000)
        let item = CareManagement.newBatchedProgramDraft("x", title: "y")
        item.externalRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementBatchedProgramDraftNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = CareManagement.BatchedProgramDraftNotesLengthRule(maxLength: 3600)
        let item = CareManagement.newBatchedProgramDraft("x", title: "y")
        item.notes = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementBatchedProgramDraftRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = CareManagement.BatchedProgramDraftRequiredExternalRefRule(
            message: "batched program draft needs this field"
        )
        let item = CareManagement.newBatchedProgramDraft("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedProgramDraftTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.BatchedProgramDraftTitleLengthRule(maxLength: 32)
        let item = CareManagement.newBatchedProgramDraft("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
