@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionSegmentTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newSubstitutionSegment("code-614", label: "label-653")
        #expect(item.status == Pharmacy.SubstitutionSegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newSubstitutionSegment("code-614", label: "label-653")
        try item.moveTo(Pharmacy.SubstitutionSegmentStatus.approved)
        #expect(item.status == Pharmacy.SubstitutionSegmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newSubstitutionSegment("code-614", label: "label-653")
        item.status = Pharmacy.SubstitutionSegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionSegmentStatus.proposed) }
    }
}
