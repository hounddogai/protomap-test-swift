@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCleaningMetricTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newLenientCleaningMetric("code-866", title: "title-738")
        #expect(item.status == BedManagement.LenientCleaningMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newLenientCleaningMetric("code-866", title: "title-738")
        try item.moveTo(BedManagement.LenientCleaningMetricStatus.granted)
        #expect(item.status == BedManagement.LenientCleaningMetricStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newLenientCleaningMetric("code-866", title: "title-738")
        item.status = BedManagement.LenientCleaningMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientCleaningMetricStatus.requested) }
    }
}
