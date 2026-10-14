@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveSubstitutionBundleTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newAdaptiveSubstitutionBundle("code-713", title: "title-130")
        #expect(item.status == Pharmacy.AdaptiveSubstitutionBundleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newAdaptiveSubstitutionBundle("code-713", title: "title-130")
        try item.moveTo(Pharmacy.AdaptiveSubstitutionBundleStatus.revoked)
        #expect(item.status == Pharmacy.AdaptiveSubstitutionBundleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newAdaptiveSubstitutionBundle("code-713", title: "title-130")
        item.status = Pharmacy.AdaptiveSubstitutionBundleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveSubstitutionBundleStatus.requested) }
    }
}
