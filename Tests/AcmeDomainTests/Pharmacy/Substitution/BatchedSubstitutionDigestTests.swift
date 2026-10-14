@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedSubstitutionDigestTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newBatchedSubstitutionDigest("code-767", title: "title-738")
        #expect(item.status == Pharmacy.BatchedSubstitutionDigestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newBatchedSubstitutionDigest("code-767", title: "title-738")
        try item.moveTo(Pharmacy.BatchedSubstitutionDigestStatus.ready)
        #expect(item.status == Pharmacy.BatchedSubstitutionDigestStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newBatchedSubstitutionDigest("code-767", title: "title-738")
        item.status = Pharmacy.BatchedSubstitutionDigestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedSubstitutionDigestStatus.idle) }
    }
}
