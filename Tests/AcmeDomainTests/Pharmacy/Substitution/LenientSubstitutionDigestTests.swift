@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientSubstitutionDigestTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newLenientSubstitutionDigest("code-412", title: "title-460")
        #expect(item.status == Pharmacy.LenientSubstitutionDigestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newLenientSubstitutionDigest("code-412", title: "title-460")
        try item.moveTo(Pharmacy.LenientSubstitutionDigestStatus.revoked)
        #expect(item.status == Pharmacy.LenientSubstitutionDigestStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newLenientSubstitutionDigest("code-412", title: "title-460")
        item.status = Pharmacy.LenientSubstitutionDigestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientSubstitutionDigestStatus.requested) }
    }
}
