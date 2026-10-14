@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierEstimateTests {
    @Test func startsInNew() throws {
        let item = Labs.newCourierEstimate("code-533", title: "title-138")
        #expect(item.status == Labs.CourierEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newCourierEstimate("code-533", title: "title-138")
        try item.moveTo(Labs.CourierEstimateStatus.running)
        #expect(item.status == Labs.CourierEstimateStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newCourierEstimate("code-533", title: "title-138")
        item.status = Labs.CourierEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierEstimateStatus.new) }
    }
}
