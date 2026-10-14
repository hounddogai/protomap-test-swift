@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryRecallDigestTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newPrimaryRecallDigest("code-429", name: "name-668")
        #expect(item.status == Pharmacy.PrimaryRecallDigestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newPrimaryRecallDigest("code-429", name: "name-668")
        try item.moveTo(Pharmacy.PrimaryRecallDigestStatus.pending)
        #expect(item.status == Pharmacy.PrimaryRecallDigestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newPrimaryRecallDigest("code-429", name: "name-668")
        item.status = Pharmacy.PrimaryRecallDigestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimaryRecallDigestStatus.draft) }
    }
}
