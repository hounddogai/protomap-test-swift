@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalCareProtocolBatchTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newGlobalCareProtocolBatch("code-81", label: "label-503")
        #expect(item.status == Imaging.GlobalCareProtocolBatchStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newGlobalCareProtocolBatch("code-81", label: "label-503")
        try item.moveTo(Imaging.GlobalCareProtocolBatchStatus.revoked)
        #expect(item.status == Imaging.GlobalCareProtocolBatchStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newGlobalCareProtocolBatch("code-81", label: "label-503")
        item.status = Imaging.GlobalCareProtocolBatchStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.GlobalCareProtocolBatchStatus.requested) }
    }
}
