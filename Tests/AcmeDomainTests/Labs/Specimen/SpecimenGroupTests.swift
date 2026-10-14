@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenGroupTests {
    @Test func startsInRequested() throws {
        let item = Labs.newSpecimenGroup("code-84", name: "name-255")
        #expect(item.status == Labs.SpecimenGroupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newSpecimenGroup("code-84", name: "name-255")
        try item.moveTo(Labs.SpecimenGroupStatus.granted)
        #expect(item.status == Labs.SpecimenGroupStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newSpecimenGroup("code-84", name: "name-255")
        item.status = Labs.SpecimenGroupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenGroupStatus.requested) }
    }
}
