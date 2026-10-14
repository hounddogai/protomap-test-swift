@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingSubstitutionClaimTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newRollingSubstitutionClaim("code-745", title: "title-293")
        #expect(item.status == Pharmacy.RollingSubstitutionClaimStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newRollingSubstitutionClaim("code-745", title: "title-293")
        try item.moveTo(Pharmacy.RollingSubstitutionClaimStatus.revoked)
        #expect(item.status == Pharmacy.RollingSubstitutionClaimStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newRollingSubstitutionClaim("code-745", title: "title-293")
        item.status = Pharmacy.RollingSubstitutionClaimStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingSubstitutionClaimStatus.requested) }
    }
}
