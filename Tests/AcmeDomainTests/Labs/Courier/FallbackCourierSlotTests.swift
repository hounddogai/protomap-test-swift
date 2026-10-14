@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierSlotTests {
    @Test func startsInIdle() throws {
        let item = Labs.newFallbackCourierSlot("code-121", name: "name-266")
        #expect(item.status == Labs.FallbackCourierSlotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newFallbackCourierSlot("code-121", name: "name-266")
        try item.moveTo(Labs.FallbackCourierSlotStatus.draining)
        #expect(item.status == Labs.FallbackCourierSlotStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newFallbackCourierSlot("code-121", name: "name-266")
        item.status = Labs.FallbackCourierSlotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackCourierSlotStatus.idle) }
    }
}
