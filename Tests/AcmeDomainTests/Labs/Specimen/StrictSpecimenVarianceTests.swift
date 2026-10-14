@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictSpecimenVarianceTests {
    @Test func startsInProposed() throws {
        let item = Labs.newStrictSpecimenVariance("code-86", title: "title-765")
        #expect(item.status == Labs.StrictSpecimenVarianceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newStrictSpecimenVariance("code-86", title: "title-765")
        try item.moveTo(Labs.StrictSpecimenVarianceStatus.approved)
        #expect(item.status == Labs.StrictSpecimenVarianceStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newStrictSpecimenVariance("code-86", title: "title-765")
        item.status = Labs.StrictSpecimenVarianceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.StrictSpecimenVarianceStatus.proposed) }
    }
}
