@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramBatchTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newProgramBatch("code-640", label: "label-55")
        #expect(item.status == CareManagement.ProgramBatchStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newProgramBatch("code-640", label: "label-55")
        try item.moveTo(CareManagement.ProgramBatchStatus.validated)
        #expect(item.status == CareManagement.ProgramBatchStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newProgramBatch("code-640", label: "label-55")
        item.status = CareManagement.ProgramBatchStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramBatchStatus.created) }
    }
}
