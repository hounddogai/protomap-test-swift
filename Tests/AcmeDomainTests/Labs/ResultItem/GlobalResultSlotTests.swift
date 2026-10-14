@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalResultSlotTests {
    @Test func startsInIdle() throws {
        let item = Labs.newGlobalResultSlot("code-823", name: "name-939")
        #expect(item.status == Labs.GlobalResultSlotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newGlobalResultSlot("code-823", name: "name-939")
        try item.moveTo(Labs.GlobalResultSlotStatus.warming)
        #expect(item.status == Labs.GlobalResultSlotStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newGlobalResultSlot("code-823", name: "name-939")
        item.status = Labs.GlobalResultSlotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalResultSlotStatus.idle) }
    }
}
