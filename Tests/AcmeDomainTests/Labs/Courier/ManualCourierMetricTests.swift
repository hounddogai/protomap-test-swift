@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualCourierMetricTests {
    @Test func startsInOpen() throws {
        let item = Labs.newManualCourierMetric("code-714", title: "title-625")
        #expect(item.status == Labs.ManualCourierMetricStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newManualCourierMetric("code-714", title: "title-625")
        try item.moveTo(Labs.ManualCourierMetricStatus.resolved)
        #expect(item.status == Labs.ManualCourierMetricStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newManualCourierMetric("code-714", title: "title-625")
        item.status = Labs.ManualCourierMetricStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ManualCourierMetricStatus.`open`) }
    }
}
