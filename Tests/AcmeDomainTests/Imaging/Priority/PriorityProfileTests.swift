@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityProfileTests {
    @Test func startsInNew() throws {
        let item = Imaging.newPriorityProfile("code-473", title: "title-847")
        #expect(item.status == Imaging.PriorityProfileStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newPriorityProfile("code-473", title: "title-847")
        try item.moveTo(Imaging.PriorityProfileStatus.running)
        #expect(item.status == Imaging.PriorityProfileStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newPriorityProfile("code-473", title: "title-847")
        item.status = Imaging.PriorityProfileStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityProfileStatus.new) }
    }
}
