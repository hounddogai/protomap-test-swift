@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionSegmentTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newDefaultInteractionSegment("code-763", title: "title-398")
        #expect(item.status == Pharmacy.DefaultInteractionSegmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newDefaultInteractionSegment("code-763", title: "title-398")
        try item.moveTo(Pharmacy.DefaultInteractionSegmentStatus.validated)
        #expect(item.status == Pharmacy.DefaultInteractionSegmentStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newDefaultInteractionSegment("code-763", title: "title-398")
        item.status = Pharmacy.DefaultInteractionSegmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultInteractionSegmentStatus.created) }
    }
}
