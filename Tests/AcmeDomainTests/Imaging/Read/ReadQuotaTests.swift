@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadQuotaTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newReadQuota("code-686", title: "title-562")
        #expect(item.status == Imaging.ReadQuotaStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newReadQuota("code-686", title: "title-562")
        try item.moveTo(Imaging.ReadQuotaStatus.approved)
        #expect(item.status == Imaging.ReadQuotaStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newReadQuota("code-686", title: "title-562")
        item.status = Imaging.ReadQuotaStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadQuotaStatus.proposed) }
    }
}
