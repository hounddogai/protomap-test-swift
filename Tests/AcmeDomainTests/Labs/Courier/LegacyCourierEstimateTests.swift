@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyCourierEstimateTests {
    @Test func startsInCreated() throws {
        let item = Labs.newLegacyCourierEstimate("code-566", name: "name-702")
        #expect(item.status == Labs.LegacyCourierEstimateStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Labs.newLegacyCourierEstimate("code-566", name: "name-702")
        try item.moveTo(Labs.LegacyCourierEstimateStatus.published)
        #expect(item.status == Labs.LegacyCourierEstimateStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newLegacyCourierEstimate("code-566", name: "name-702")
        item.status = Labs.LegacyCourierEstimateStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyCourierEstimateStatus.created) }
    }
}
