@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionBundleTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newPrimarySubstitutionBundle("code-255", name: "name-95")
        #expect(item.status == Pharmacy.PrimarySubstitutionBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newPrimarySubstitutionBundle("code-255", name: "name-95")
        try item.moveTo(Pharmacy.PrimarySubstitutionBundleStatus.draining)
        #expect(item.status == Pharmacy.PrimarySubstitutionBundleStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newPrimarySubstitutionBundle("code-255", name: "name-95")
        item.status = Pharmacy.PrimarySubstitutionBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimarySubstitutionBundleStatus.idle) }
    }
}
