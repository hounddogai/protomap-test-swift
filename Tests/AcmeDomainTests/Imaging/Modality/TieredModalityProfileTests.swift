@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredModalityProfileTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newTieredModalityProfile("code-934", name: "name-228")
        #expect(item.status == Imaging.TieredModalityProfileStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Imaging.newTieredModalityProfile("code-934", name: "name-228")
        try item.moveTo(Imaging.TieredModalityProfileStatus.completed)
        #expect(item.status == Imaging.TieredModalityProfileStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newTieredModalityProfile("code-934", name: "name-228")
        item.status = Imaging.TieredModalityProfileStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredModalityProfileStatus.planned) }
    }
}
