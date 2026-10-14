@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenDigestTests {
    @Test func startsInProposed() throws {
        let item = Labs.newSpecimenDigest("code-821", name: "name-638")
        #expect(item.status == Labs.SpecimenDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newSpecimenDigest("code-821", name: "name-638")
        try item.moveTo(Labs.SpecimenDigestStatus.approved)
        #expect(item.status == Labs.SpecimenDigestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newSpecimenDigest("code-821", name: "name-638")
        item.status = Labs.SpecimenDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenDigestStatus.proposed) }
    }
}
