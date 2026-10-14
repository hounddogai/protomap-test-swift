@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingModalityPolicyTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newPendingModalityPolicy("code-626", title: "title-304")
        #expect(item.status == Imaging.PendingModalityPolicyStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Imaging.newPendingModalityPolicy("code-626", title: "title-304")
        try item.moveTo(Imaging.PendingModalityPolicyStatus.resolved)
        #expect(item.status == Imaging.PendingModalityPolicyStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newPendingModalityPolicy("code-626", title: "title-304")
        item.status = Imaging.PendingModalityPolicyStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PendingModalityPolicyStatus.`open`) }
    }
}
