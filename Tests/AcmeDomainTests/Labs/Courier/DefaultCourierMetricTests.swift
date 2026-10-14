@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultCourierMetricTests {
    @Test func startsInProposed() throws {
        let item = Labs.newDefaultCourierMetric("code-43", label: "label-580")
        #expect(item.status == Labs.DefaultCourierMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newDefaultCourierMetric("code-43", label: "label-580")
        try item.moveTo(Labs.DefaultCourierMetricStatus.approved)
        #expect(item.status == Labs.DefaultCourierMetricStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newDefaultCourierMetric("code-43", label: "label-580")
        item.status = Labs.DefaultCourierMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultCourierMetricStatus.proposed) }
    }
}
