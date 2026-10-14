@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolEntryTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newCareProtocolEntry("code-377", name: "name-80")
        #expect(item.status == Imaging.CareProtocolEntryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Imaging.newCareProtocolEntry("code-377", name: "name-80")
        try item.moveTo(Imaging.CareProtocolEntryStatus.cancelled)
        #expect(item.status == Imaging.CareProtocolEntryStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newCareProtocolEntry("code-377", name: "name-80")
        item.status = Imaging.CareProtocolEntryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolEntryStatus.planned) }
    }
}
