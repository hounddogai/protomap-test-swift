@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenProfileTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newSpecimenProfile("code-737", name: "name-452")
        #expect(item.status == Labs.SpecimenProfileStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Labs.newSpecimenProfile("code-737", name: "name-452")
        try item.moveTo(Labs.SpecimenProfileStatus.inProgress)
        #expect(item.status == Labs.SpecimenProfileStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newSpecimenProfile("code-737", name: "name-452")
        item.status = Labs.SpecimenProfileStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenProfileStatus.planned) }
    }
}
