@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadClaimTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newReadClaim("code-197", name: "name-790")
        #expect(item.status == Imaging.ReadClaimStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Imaging.newReadClaim("code-197", name: "name-790")
        try item.moveTo(Imaging.ReadClaimStatus.active)
        #expect(item.status == Imaging.ReadClaimStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newReadClaim("code-197", name: "name-790")
        item.status = Imaging.ReadClaimStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadClaimStatus.draft) }
    }
}
