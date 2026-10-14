@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityDigestTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newPriorityDigest("code-27", title: "title-228")
        #expect(item.status == Imaging.PriorityDigestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Imaging.newPriorityDigest("code-27", title: "title-228")
        try item.moveTo(Imaging.PriorityDigestStatus.expired)
        #expect(item.status == Imaging.PriorityDigestStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newPriorityDigest("code-27", title: "title-228")
        item.status = Imaging.PriorityDigestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityDigestStatus.requested) }
    }
}
