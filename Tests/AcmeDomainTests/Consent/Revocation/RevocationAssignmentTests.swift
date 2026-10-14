@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationAssignmentTests {
    @Test func startsInProposed() throws {
        let item = Consent.newRevocationAssignment("code-942", name: "name-913")
        #expect(item.status == Consent.RevocationAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newRevocationAssignment("code-942", name: "name-913")
        try item.moveTo(Consent.RevocationAssignmentStatus.rejected)
        #expect(item.status == Consent.RevocationAssignmentStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newRevocationAssignment("code-942", name: "name-913")
        item.status = Consent.RevocationAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationAssignmentStatus.proposed) }
    }
}
