@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultSubstitutionTierTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newDefaultSubstitutionTier("code-76", name: "name-40")
        #expect(item.status == Pharmacy.DefaultSubstitutionTierStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newDefaultSubstitutionTier("code-76", name: "name-40")
        try item.moveTo(Pharmacy.DefaultSubstitutionTierStatus.warming)
        #expect(item.status == Pharmacy.DefaultSubstitutionTierStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newDefaultSubstitutionTier("code-76", name: "name-40")
        item.status = Pharmacy.DefaultSubstitutionTierStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultSubstitutionTierStatus.idle) }
    }
}
