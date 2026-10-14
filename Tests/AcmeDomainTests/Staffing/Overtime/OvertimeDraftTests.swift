@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeDraftTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newOvertimeDraft("code-597", label: "label-778")
        #expect(item.status == Staffing.OvertimeDraftStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Staffing.newOvertimeDraft("code-597", label: "label-778")
        try item.moveTo(Staffing.OvertimeDraftStatus.retired)
        #expect(item.status == Staffing.OvertimeDraftStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newOvertimeDraft("code-597", label: "label-778")
        item.status = Staffing.OvertimeDraftStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeDraftStatus.created) }
    }
}
