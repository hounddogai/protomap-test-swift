@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultRequestTests {
    @Test func startsInNew() throws {
        let item = Labs.newAdaptiveResultRequest("code-155", label: "label-457")
        #expect(item.status == Labs.AdaptiveResultRequestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newAdaptiveResultRequest("code-155", label: "label-457")
        try item.moveTo(Labs.AdaptiveResultRequestStatus.queued)
        #expect(item.status == Labs.AdaptiveResultRequestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newAdaptiveResultRequest("code-155", label: "label-457")
        item.status = Labs.AdaptiveResultRequestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptiveResultRequestStatus.new) }
    }
}
