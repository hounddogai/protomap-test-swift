@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallSegmentTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newRecallSegment("code-168", name: "name-681")
        #expect(item.status == Pharmacy.RecallSegmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newRecallSegment("code-168", name: "name-681")
        try item.moveTo(Pharmacy.RecallSegmentStatus.revoked)
        #expect(item.status == Pharmacy.RecallSegmentStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newRecallSegment("code-168", name: "name-681")
        item.status = Pharmacy.RecallSegmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallSegmentStatus.requested) }
    }
}
