@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualSubstitutionDigestTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newManualSubstitutionDigest("code-835", name: "name-699")
        #expect(item.status == Pharmacy.ManualSubstitutionDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newManualSubstitutionDigest("code-835", name: "name-699")
        try item.moveTo(Pharmacy.ManualSubstitutionDigestStatus.rejected)
        #expect(item.status == Pharmacy.ManualSubstitutionDigestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newManualSubstitutionDigest("code-835", name: "name-699")
        item.status = Pharmacy.ManualSubstitutionDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualSubstitutionDigestStatus.proposed) }
    }
}
