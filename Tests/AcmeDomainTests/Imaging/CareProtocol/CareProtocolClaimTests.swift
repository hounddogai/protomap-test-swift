@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolClaimTests {
    @Test func startsInNew() throws {
        let item = Imaging.newCareProtocolClaim("code-834", title: "title-799")
        #expect(item.status == Imaging.CareProtocolClaimStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Imaging.newCareProtocolClaim("code-834", title: "title-799")
        try item.moveTo(Imaging.CareProtocolClaimStatus.done)
        #expect(item.status == Imaging.CareProtocolClaimStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newCareProtocolClaim("code-834", title: "title-799")
        item.status = Imaging.CareProtocolClaimStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolClaimStatus.new) }
    }
}
