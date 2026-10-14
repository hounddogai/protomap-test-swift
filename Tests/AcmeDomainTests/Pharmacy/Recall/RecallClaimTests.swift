@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallClaimTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newRecallClaim("code-55", name: "name-771")
        #expect(item.status == Pharmacy.RecallClaimStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Pharmacy.newRecallClaim("code-55", name: "name-771")
        try item.moveTo(Pharmacy.RecallClaimStatus.stopped)
        #expect(item.status == Pharmacy.RecallClaimStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newRecallClaim("code-55", name: "name-771")
        item.status = Pharmacy.RecallClaimStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallClaimStatus.idle) }
    }
}
