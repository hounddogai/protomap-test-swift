@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningClaimTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newCleaningClaim("code-422", title: "title-475")
        #expect(item.status == BedManagement.CleaningClaimStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newCleaningClaim("code-422", title: "title-475")
        try item.moveTo(BedManagement.CleaningClaimStatus.validated)
        #expect(item.status == BedManagement.CleaningClaimStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newCleaningClaim("code-422", title: "title-475")
        item.status = BedManagement.CleaningClaimStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningClaimStatus.created) }
    }
}
