@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallClaimTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newManualRecallClaim("code-709", title: "title-443")
        #expect(item.status == Pharmacy.ManualRecallClaimStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newManualRecallClaim("code-709", title: "title-443")
        try item.moveTo(Pharmacy.ManualRecallClaimStatus.suspended)
        #expect(item.status == Pharmacy.ManualRecallClaimStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newManualRecallClaim("code-709", title: "title-443")
        item.status = Pharmacy.ManualRecallClaimStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualRecallClaimStatus.draft) }
    }
}
