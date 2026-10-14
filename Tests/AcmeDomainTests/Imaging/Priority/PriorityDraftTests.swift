@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityDraftTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newPriorityDraft("code-680", title: "title-604")
        #expect(item.status == Imaging.PriorityDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Imaging.newPriorityDraft("code-680", title: "title-604")
        try item.moveTo(Imaging.PriorityDraftStatus.expired)
        #expect(item.status == Imaging.PriorityDraftStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newPriorityDraft("code-680", title: "title-604")
        item.status = Imaging.PriorityDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityDraftStatus.requested) }
    }
}
