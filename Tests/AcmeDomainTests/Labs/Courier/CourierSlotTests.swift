@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierSlotTests {
    @Test func startsInNew() throws {
        let item = Labs.newCourierSlot("code-678", name: "name-232")
        #expect(item.status == Labs.CourierSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Labs.newCourierSlot("code-678", name: "name-232")
        try item.moveTo(Labs.CourierSlotStatus.done)
        #expect(item.status == Labs.CourierSlotStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newCourierSlot("code-678", name: "name-232")
        item.status = Labs.CourierSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierSlotStatus.new) }
    }
}
