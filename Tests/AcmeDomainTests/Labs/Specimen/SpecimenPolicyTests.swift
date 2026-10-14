@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenPolicyTests {
    @Test func startsInOpen() throws {
        let item = Labs.newSpecimenPolicy("code-226", title: "title-359")
        #expect(item.status == Labs.SpecimenPolicyStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newSpecimenPolicy("code-226", title: "title-359")
        try item.moveTo(Labs.SpecimenPolicyStatus.resolved)
        #expect(item.status == Labs.SpecimenPolicyStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newSpecimenPolicy("code-226", title: "title-359")
        item.status = Labs.SpecimenPolicyStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenPolicyStatus.`open`) }
    }
}
