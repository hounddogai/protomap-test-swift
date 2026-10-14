@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedCourierMetricTests {
    @Test func startsInIdle() throws {
        let item = Labs.newCappedCourierMetric("code-658", name: "name-302")
        #expect(item.status == Labs.CappedCourierMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newCappedCourierMetric("code-658", name: "name-302")
        try item.moveTo(Labs.CappedCourierMetricStatus.draining)
        #expect(item.status == Labs.CappedCourierMetricStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newCappedCourierMetric("code-658", name: "name-302")
        item.status = Labs.CappedCourierMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedCourierMetricStatus.idle) }
    }
}
