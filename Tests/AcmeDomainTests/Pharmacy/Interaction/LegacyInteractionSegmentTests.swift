@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionSegmentTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newLegacyInteractionSegment("code-562", label: "label-238")
        #expect(item.status == Pharmacy.LegacyInteractionSegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newLegacyInteractionSegment("code-562", label: "label-238")
        try item.moveTo(Pharmacy.LegacyInteractionSegmentStatus.approved)
        #expect(item.status == Pharmacy.LegacyInteractionSegmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newLegacyInteractionSegment("code-562", label: "label-238")
        item.status = Pharmacy.LegacyInteractionSegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyInteractionSegmentStatus.proposed) }
    }
}
