@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseClaimTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newDispenseClaim("code-318", title: "title-270")
        #expect(item.status == Pharmacy.DispenseClaimStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newDispenseClaim("code-318", title: "title-270")
        try item.moveTo(Pharmacy.DispenseClaimStatus.draining)
        #expect(item.status == Pharmacy.DispenseClaimStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newDispenseClaim("code-318", title: "title-270")
        item.status = Pharmacy.DispenseClaimStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseClaimStatus.idle) }
    }
}
