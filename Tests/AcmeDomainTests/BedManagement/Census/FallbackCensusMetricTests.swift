@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCensusMetricTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newFallbackCensusMetric("code-812", name: "name-969")
        #expect(item.status == BedManagement.FallbackCensusMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newFallbackCensusMetric("code-812", name: "name-969")
        try item.moveTo(BedManagement.FallbackCensusMetricStatus.granted)
        #expect(item.status == BedManagement.FallbackCensusMetricStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newFallbackCensusMetric("code-812", name: "name-969")
        item.status = BedManagement.FallbackCensusMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackCensusMetricStatus.requested) }
    }
}
