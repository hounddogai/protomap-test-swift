@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCensusDraftTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newAdaptiveCensusDraft("code-151", label: "label-436")
        #expect(item.status == BedManagement.AdaptiveCensusDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newAdaptiveCensusDraft("code-151", label: "label-436")
        try item.moveTo(BedManagement.AdaptiveCensusDraftStatus.granted)
        #expect(item.status == BedManagement.AdaptiveCensusDraftStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newAdaptiveCensusDraft("code-151", label: "label-436")
        item.status = BedManagement.AdaptiveCensusDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveCensusDraftStatus.requested) }
    }
}
