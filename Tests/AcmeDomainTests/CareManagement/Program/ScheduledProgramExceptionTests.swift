@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledProgramExceptionTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newScheduledProgramException("code-558", label: "label-485")
        #expect(item.status == CareManagement.ScheduledProgramExceptionStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newScheduledProgramException("code-558", label: "label-485")
        try item.moveTo(CareManagement.ScheduledProgramExceptionStatus.granted)
        #expect(item.status == CareManagement.ScheduledProgramExceptionStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newScheduledProgramException("code-558", label: "label-485")
        item.status = CareManagement.ScheduledProgramExceptionStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledProgramExceptionStatus.requested) }
    }
}
