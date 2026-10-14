@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyCareProtocolThresholdTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newLegacyCareProtocolThreshold("code-803", title: "title-214")
        #expect(item.status == Imaging.LegacyCareProtocolThresholdStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Imaging.newLegacyCareProtocolThreshold("code-803", title: "title-214")
        try item.moveTo(Imaging.LegacyCareProtocolThresholdStatus.retired)
        #expect(item.status == Imaging.LegacyCareProtocolThresholdStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newLegacyCareProtocolThreshold("code-803", title: "title-214")
        item.status = Imaging.LegacyCareProtocolThresholdStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LegacyCareProtocolThresholdStatus.created) }
    }
}
