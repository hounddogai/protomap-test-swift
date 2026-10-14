@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningExceptionTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newCleaningException("code-943", label: "label-218")
        #expect(item.status == BedManagement.CleaningExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newCleaningException("code-943", label: "label-218")
        try item.moveTo(BedManagement.CleaningExceptionStatus.warming)
        #expect(item.status == BedManagement.CleaningExceptionStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newCleaningException("code-943", label: "label-218")
        item.status = BedManagement.CleaningExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningExceptionStatus.idle) }
    }
}
