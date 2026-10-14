@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferProfileTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newTransferProfile("code-25", label: "label-703")
        #expect(item.status == BedManagement.TransferProfileStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = BedManagement.newTransferProfile("code-25", label: "label-703")
        try item.moveTo(BedManagement.TransferProfileStatus.stopped)
        #expect(item.status == BedManagement.TransferProfileStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newTransferProfile("code-25", label: "label-703")
        item.status = BedManagement.TransferProfileStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferProfileStatus.idle) }
    }
}
