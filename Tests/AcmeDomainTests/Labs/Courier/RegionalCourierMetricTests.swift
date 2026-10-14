@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalCourierMetricTests {
    @Test func startsInRequested() throws {
        let item = Labs.newRegionalCourierMetric("code-953", label: "label-796")
        #expect(item.status == Labs.RegionalCourierMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Labs.newRegionalCourierMetric("code-953", label: "label-796")
        try item.moveTo(Labs.RegionalCourierMetricStatus.revoked)
        #expect(item.status == Labs.RegionalCourierMetricStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newRegionalCourierMetric("code-953", label: "label-796")
        item.status = Labs.RegionalCourierMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RegionalCourierMetricStatus.requested) }
    }
}
