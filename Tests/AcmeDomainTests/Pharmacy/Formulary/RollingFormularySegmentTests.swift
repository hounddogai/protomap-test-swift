@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingFormularySegmentTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newRollingFormularySegment("code-989", label: "label-106")
        #expect(item.status == Pharmacy.RollingFormularySegmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newRollingFormularySegment("code-989", label: "label-106")
        try item.moveTo(Pharmacy.RollingFormularySegmentStatus.retired)
        #expect(item.status == Pharmacy.RollingFormularySegmentStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newRollingFormularySegment("code-989", label: "label-106")
        item.status = Pharmacy.RollingFormularySegmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingFormularySegmentStatus.created) }
    }
}
