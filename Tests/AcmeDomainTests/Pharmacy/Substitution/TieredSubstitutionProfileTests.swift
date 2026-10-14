@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredSubstitutionProfileTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newTieredSubstitutionProfile("code-853", label: "label-811")
        #expect(item.status == Pharmacy.TieredSubstitutionProfileStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newTieredSubstitutionProfile("code-853", label: "label-811")
        try item.moveTo(Pharmacy.TieredSubstitutionProfileStatus.revoked)
        #expect(item.status == Pharmacy.TieredSubstitutionProfileStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newTieredSubstitutionProfile("code-853", label: "label-811")
        item.status = Pharmacy.TieredSubstitutionProfileStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.TieredSubstitutionProfileStatus.requested) }
    }
}
