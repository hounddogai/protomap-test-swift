@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenWindowTests {
    @Test func startsInProposed() throws {
        let item = Labs.newSpecimenWindow("code-448", title: "title-971")
        #expect(item.status == Labs.SpecimenWindowStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newSpecimenWindow("code-448", title: "title-971")
        try item.moveTo(Labs.SpecimenWindowStatus.approved)
        #expect(item.status == Labs.SpecimenWindowStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newSpecimenWindow("code-448", title: "title-971")
        item.status = Labs.SpecimenWindowStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenWindowStatus.proposed) }
    }
}
