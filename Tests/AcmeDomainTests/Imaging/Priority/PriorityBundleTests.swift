@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityBundleTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newPriorityBundle("code-301", title: "title-245")
        #expect(item.status == Imaging.PriorityBundleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Imaging.newPriorityBundle("code-301", title: "title-245")
        try item.moveTo(Imaging.PriorityBundleStatus.completed)
        #expect(item.status == Imaging.PriorityBundleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newPriorityBundle("code-301", title: "title-245")
        item.status = Imaging.PriorityBundleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityBundleStatus.planned) }
    }
}
