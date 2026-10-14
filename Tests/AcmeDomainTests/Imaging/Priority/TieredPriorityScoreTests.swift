@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredPriorityScoreTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newTieredPriorityScore("code-697", name: "name-300")
        #expect(item.status == Imaging.TieredPriorityScoreStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newTieredPriorityScore("code-697", name: "name-300")
        try item.moveTo(Imaging.TieredPriorityScoreStatus.published)
        #expect(item.status == Imaging.TieredPriorityScoreStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newTieredPriorityScore("code-697", name: "name-300")
        item.status = Imaging.TieredPriorityScoreStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredPriorityScoreStatus.created) }
    }
}
