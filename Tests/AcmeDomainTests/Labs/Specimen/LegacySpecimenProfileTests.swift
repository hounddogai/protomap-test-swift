@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacySpecimenProfileTests {
    @Test func startsInProposed() throws {
        let item = Labs.newLegacySpecimenProfile("code-51", label: "label-688")
        #expect(item.status == Labs.LegacySpecimenProfileStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newLegacySpecimenProfile("code-51", label: "label-688")
        try item.moveTo(Labs.LegacySpecimenProfileStatus.approved)
        #expect(item.status == Labs.LegacySpecimenProfileStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newLegacySpecimenProfile("code-51", label: "label-688")
        item.status = Labs.LegacySpecimenProfileStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacySpecimenProfileStatus.proposed) }
    }
}
