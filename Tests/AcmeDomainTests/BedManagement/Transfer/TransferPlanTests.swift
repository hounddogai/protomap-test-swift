@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferPlanTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newTransferPlan("code-258", title: "title-478")
        #expect(item.status == BedManagement.TransferPlanStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newTransferPlan("code-258", title: "title-478")
        try item.moveTo(BedManagement.TransferPlanStatus.granted)
        #expect(item.status == BedManagement.TransferPlanStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newTransferPlan("code-258", title: "title-478")
        item.status = BedManagement.TransferPlanStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferPlanStatus.requested) }
    }
}
