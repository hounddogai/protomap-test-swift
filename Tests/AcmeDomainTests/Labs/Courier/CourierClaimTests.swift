@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierClaimTests {
    @Test func startsInProposed() throws {
        let item = Labs.newCourierClaim("code-561", name: "name-985")
        #expect(item.status == Labs.CourierClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newCourierClaim("code-561", name: "name-985")
        try item.moveTo(Labs.CourierClaimStatus.approved)
        #expect(item.status == Labs.CourierClaimStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newCourierClaim("code-561", name: "name-985")
        item.status = Labs.CourierClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierClaimStatus.proposed) }
    }
}
