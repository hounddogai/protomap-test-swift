@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallDigestTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newRecallDigest("code-9", title: "title-239")
        #expect(item.status == Pharmacy.RecallDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newRecallDigest("code-9", title: "title-239")
        try item.moveTo(Pharmacy.RecallDigestStatus.inProgress)
        #expect(item.status == Pharmacy.RecallDigestStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newRecallDigest("code-9", title: "title-239")
        item.status = Pharmacy.RecallDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallDigestStatus.planned) }
    }
}
