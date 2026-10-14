@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolTierTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newCareProtocolTier("code-400", title: "title-589")
        #expect(item.status == Imaging.CareProtocolTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newCareProtocolTier("code-400", title: "title-589")
        try item.moveTo(Imaging.CareProtocolTierStatus.scheduled)
        #expect(item.status == Imaging.CareProtocolTierStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newCareProtocolTier("code-400", title: "title-589")
        item.status = Imaging.CareProtocolTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolTierStatus.planned) }
    }
}
