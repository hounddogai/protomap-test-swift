@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityRequestTests {
    @Test func startsInNew() throws {
        let item = Imaging.newPriorityRequest("code-667", name: "name-65")
        #expect(item.status == Imaging.PriorityRequestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newPriorityRequest("code-667", name: "name-65")
        try item.moveTo(Imaging.PriorityRequestStatus.queued)
        #expect(item.status == Imaging.PriorityRequestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newPriorityRequest("code-667", name: "name-65")
        item.status = Imaging.PriorityRequestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityRequestStatus.new) }
    }
}
