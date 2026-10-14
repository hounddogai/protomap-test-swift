@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyCareProtocolEntryTests {
    @Test func startsInNew() throws {
        let item = Imaging.newLegacyCareProtocolEntry("code-931", label: "label-806")
        #expect(item.status == Imaging.LegacyCareProtocolEntryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newLegacyCareProtocolEntry("code-931", label: "label-806")
        try item.moveTo(Imaging.LegacyCareProtocolEntryStatus.running)
        #expect(item.status == Imaging.LegacyCareProtocolEntryStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newLegacyCareProtocolEntry("code-931", label: "label-806")
        item.status = Imaging.LegacyCareProtocolEntryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LegacyCareProtocolEntryStatus.new) }
    }
}
