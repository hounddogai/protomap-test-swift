@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionReservationTests {
    @Test func startsInCreated() throws {
        let item = Labs.newFallbackAccessionReservation("code-338", title: "title-214")
        #expect(item.status == Labs.FallbackAccessionReservationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Labs.newFallbackAccessionReservation("code-338", title: "title-214")
        try item.moveTo(Labs.FallbackAccessionReservationStatus.published)
        #expect(item.status == Labs.FallbackAccessionReservationStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newFallbackAccessionReservation("code-338", title: "title-214")
        item.status = Labs.FallbackAccessionReservationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackAccessionReservationStatus.created) }
    }
}
