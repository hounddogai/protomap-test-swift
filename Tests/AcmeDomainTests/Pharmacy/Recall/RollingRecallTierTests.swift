@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingRecallTierTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newRollingRecallTier("code-382", name: "name-620")
        #expect(item.status == Pharmacy.RollingRecallTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newRollingRecallTier("code-382", name: "name-620")
        try item.moveTo(Pharmacy.RollingRecallTierStatus.queued)
        #expect(item.status == Pharmacy.RollingRecallTierStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newRollingRecallTier("code-382", name: "name-620")
        item.status = Pharmacy.RollingRecallTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingRecallTierStatus.new) }
    }
}
