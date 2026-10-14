@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityEntryTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newPriorityEntry("code-699", name: "name-913")
        #expect(item.status == Imaging.PriorityEntryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newPriorityEntry("code-699", name: "name-913")
        try item.moveTo(Imaging.PriorityEntryStatus.granted)
        #expect(item.status == Imaging.PriorityEntryStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newPriorityEntry("code-699", name: "name-913")
        item.status = Imaging.PriorityEntryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityEntryStatus.requested) }
    }
}
