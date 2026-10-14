@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenRequestTests {
    @Test func startsInNew() throws {
        let item = Labs.newSpecimenRequest("code-169", name: "name-515")
        #expect(item.status == Labs.SpecimenRequestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newSpecimenRequest("code-169", name: "name-515")
        try item.moveTo(Labs.SpecimenRequestStatus.running)
        #expect(item.status == Labs.SpecimenRequestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newSpecimenRequest("code-169", name: "name-515")
        item.status = Labs.SpecimenRequestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenRequestStatus.new) }
    }
}
