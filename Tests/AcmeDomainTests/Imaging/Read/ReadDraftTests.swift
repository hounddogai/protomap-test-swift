@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadDraftTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newReadDraft("code-355", label: "label-458")
        #expect(item.status == Imaging.ReadDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newReadDraft("code-355", label: "label-458")
        try item.moveTo(Imaging.ReadDraftStatus.approved)
        #expect(item.status == Imaging.ReadDraftStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newReadDraft("code-355", label: "label-458")
        item.status = Imaging.ReadDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadDraftStatus.proposed) }
    }
}
