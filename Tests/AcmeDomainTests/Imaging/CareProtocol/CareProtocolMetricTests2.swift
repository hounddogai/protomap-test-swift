@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolMetricTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newCareProtocolMetric("code-656", name: "name-223")
        #expect(item.status == Imaging.CareProtocolMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Imaging.newCareProtocolMetric("code-656", name: "name-223")
        try item.moveTo(Imaging.CareProtocolMetricStatus.stopped)
        #expect(item.status == Imaging.CareProtocolMetricStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newCareProtocolMetric("code-656", name: "name-223")
        item.status = Imaging.CareProtocolMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolMetricStatus.idle) }
    }
}
