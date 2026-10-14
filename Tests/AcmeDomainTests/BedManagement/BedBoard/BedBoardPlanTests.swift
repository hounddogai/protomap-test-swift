@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardPlanTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newBedBoardPlan("code-939", label: "label-457")
        #expect(item.status == BedManagement.BedBoardPlanStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newBedBoardPlan("code-939", label: "label-457")
        try item.moveTo(BedManagement.BedBoardPlanStatus.granted)
        #expect(item.status == BedManagement.BedBoardPlanStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newBedBoardPlan("code-939", label: "label-457")
        item.status = BedManagement.BedBoardPlanStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardPlanStatus.requested) }
    }
}
