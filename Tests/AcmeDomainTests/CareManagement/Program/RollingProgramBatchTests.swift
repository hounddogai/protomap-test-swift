@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingProgramBatchTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newRollingProgramBatch("code-223", name: "name-71")
        #expect(item.status == CareManagement.RollingProgramBatchStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = CareManagement.newRollingProgramBatch("code-223", name: "name-71")
        try item.moveTo(CareManagement.RollingProgramBatchStatus.expired)
        #expect(item.status == CareManagement.RollingProgramBatchStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newRollingProgramBatch("code-223", name: "name-71")
        item.status = CareManagement.RollingProgramBatchStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingProgramBatchStatus.requested) }
    }
}
