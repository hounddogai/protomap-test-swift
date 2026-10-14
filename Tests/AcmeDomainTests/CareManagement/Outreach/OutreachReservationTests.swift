@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachReservationTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newOutreachReservation("code-382", label: "label-314")
        #expect(item.status == CareManagement.OutreachReservationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newOutreachReservation("code-382", label: "label-314")
        try item.moveTo(CareManagement.OutreachReservationStatus.published)
        #expect(item.status == CareManagement.OutreachReservationStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newOutreachReservation("code-382", label: "label-314")
        item.status = CareManagement.OutreachReservationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachReservationStatus.created) }
    }
}
