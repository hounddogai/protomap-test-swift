@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultRequestTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newLegacyResultRequest("code-593", title: "title-772")
        #expect(item.status == Labs.LegacyResultRequestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newLegacyResultRequest("code-593", title: "title-772")
        try item.moveTo(Labs.LegacyResultRequestStatus.completed)
        #expect(item.status == Labs.LegacyResultRequestStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newLegacyResultRequest("code-593", title: "title-772")
        item.status = Labs.LegacyResultRequestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyResultRequestStatus.planned) }
    }
}
