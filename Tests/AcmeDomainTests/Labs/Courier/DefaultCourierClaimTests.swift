@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultCourierClaimTests {
    @Test func startsInProposed() throws {
        let item = Labs.newDefaultCourierClaim("code-939", name: "name-230")
        #expect(item.status == Labs.DefaultCourierClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newDefaultCourierClaim("code-939", name: "name-230")
        try item.moveTo(Labs.DefaultCourierClaimStatus.approved)
        #expect(item.status == Labs.DefaultCourierClaimStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newDefaultCourierClaim("code-939", name: "name-230")
        item.status = Labs.DefaultCourierClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultCourierClaimStatus.proposed) }
    }
}
