@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolPolicyTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newFallbackCareProtocolPolicy("code-962", title: "title-368")
        #expect(item.status == Imaging.FallbackCareProtocolPolicyStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Imaging.newFallbackCareProtocolPolicy("code-962", title: "title-368")
        try item.moveTo(Imaging.FallbackCareProtocolPolicyStatus.active)
        #expect(item.status == Imaging.FallbackCareProtocolPolicyStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newFallbackCareProtocolPolicy("code-962", title: "title-368")
        item.status = Imaging.FallbackCareProtocolPolicyStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.FallbackCareProtocolPolicyStatus.draft) }
    }
}
