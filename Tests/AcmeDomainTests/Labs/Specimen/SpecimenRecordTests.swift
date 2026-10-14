@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenRecordTests {
    @Test func startsInDraft() throws {
        let item = Labs.newSpecimenRecord("code-38", name: "name-773")
        #expect(item.status == Labs.SpecimenRecordStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Labs.newSpecimenRecord("code-38", name: "name-773")
        try item.moveTo(Labs.SpecimenRecordStatus.suspended)
        #expect(item.status == Labs.SpecimenRecordStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newSpecimenRecord("code-38", name: "name-773")
        item.status = Labs.SpecimenRecordStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenRecordStatus.draft) }
    }
}
