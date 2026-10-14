@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolBatchTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newCareProtocolBatch("code-678", name: "name-965")
        #expect(item.status == Imaging.CareProtocolBatchStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Imaging.newCareProtocolBatch("code-678", name: "name-965")
        try item.moveTo(Imaging.CareProtocolBatchStatus.withdrawn)
        #expect(item.status == Imaging.CareProtocolBatchStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newCareProtocolBatch("code-678", name: "name-965")
        item.status = Imaging.CareProtocolBatchStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolBatchStatus.proposed) }
    }
}
