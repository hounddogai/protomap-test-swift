@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanSnapshotTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newPrimaryAcuityPlanSnapshot("code-883", label: "label-515")
        #expect(item.status == Staffing.PrimaryAcuityPlanSnapshotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Staffing.newPrimaryAcuityPlanSnapshot("code-883", label: "label-515")
        try item.moveTo(Staffing.PrimaryAcuityPlanSnapshotStatus.expired)
        #expect(item.status == Staffing.PrimaryAcuityPlanSnapshotStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newPrimaryAcuityPlanSnapshot("code-883", label: "label-515")
        item.status = Staffing.PrimaryAcuityPlanSnapshotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryAcuityPlanSnapshotStatus.requested) }
    }
}
