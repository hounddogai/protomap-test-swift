@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanSnapshotTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newAcuityPlanSnapshot("code-475", name: "name-346")
        #expect(item.status == Staffing.AcuityPlanSnapshotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newAcuityPlanSnapshot("code-475", name: "name-346")
        try item.moveTo(Staffing.AcuityPlanSnapshotStatus.pending)
        #expect(item.status == Staffing.AcuityPlanSnapshotStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newAcuityPlanSnapshot("code-475", name: "name-346")
        item.status = Staffing.AcuityPlanSnapshotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanSnapshotStatus.draft) }
    }
}
