@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackOutreachReservationTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newFallbackOutreachReservation("code-981", title: "title-963")
        #expect(item.status == CareManagement.FallbackOutreachReservationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newFallbackOutreachReservation("code-981", title: "title-963")
        try item.moveTo(CareManagement.FallbackOutreachReservationStatus.validated)
        #expect(item.status == CareManagement.FallbackOutreachReservationStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newFallbackOutreachReservation("code-981", title: "title-963")
        item.status = CareManagement.FallbackOutreachReservationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackOutreachReservationStatus.created) }
    }
}
