@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolDigestTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newCareProtocolDigest("code-524", label: "label-615")
        #expect(item.status == Imaging.CareProtocolDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newCareProtocolDigest("code-524", label: "label-615")
        try item.moveTo(Imaging.CareProtocolDigestStatus.approved)
        #expect(item.status == Imaging.CareProtocolDigestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newCareProtocolDigest("code-524", label: "label-615")
        item.status = Imaging.CareProtocolDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolDigestStatus.proposed) }
    }
}
