@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultCourierSlotTests {
    @Test func startsInCreated() throws {
        let item = Labs.newDefaultCourierSlot("code-335", name: "name-681")
        #expect(item.status == Labs.DefaultCourierSlotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newDefaultCourierSlot("code-335", name: "name-681")
        try item.moveTo(Labs.DefaultCourierSlotStatus.validated)
        #expect(item.status == Labs.DefaultCourierSlotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newDefaultCourierSlot("code-335", name: "name-681")
        item.status = Labs.DefaultCourierSlotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultCourierSlotStatus.created) }
    }
}
