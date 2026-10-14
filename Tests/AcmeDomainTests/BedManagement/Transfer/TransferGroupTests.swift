@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferGroupTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newTransferGroup("code-703", name: "name-207")
        #expect(item.status == BedManagement.TransferGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newTransferGroup("code-703", name: "name-207")
        try item.moveTo(BedManagement.TransferGroupStatus.running)
        #expect(item.status == BedManagement.TransferGroupStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newTransferGroup("code-703", name: "name-207")
        item.status = BedManagement.TransferGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferGroupStatus.new) }
    }
}
