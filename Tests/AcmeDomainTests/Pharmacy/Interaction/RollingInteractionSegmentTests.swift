@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInteractionSegmentTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newRollingInteractionSegment("code-666", label: "label-653")
        #expect(item.status == Pharmacy.RollingInteractionSegmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newRollingInteractionSegment("code-666", label: "label-653")
        try item.moveTo(Pharmacy.RollingInteractionSegmentStatus.revoked)
        #expect(item.status == Pharmacy.RollingInteractionSegmentStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newRollingInteractionSegment("code-666", label: "label-653")
        item.status = Pharmacy.RollingInteractionSegmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingInteractionSegmentStatus.requested) }
    }
}
