@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialSlotTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newCredentialSlot("code-54", label: "label-579")
        #expect(item.status == Staffing.CredentialSlotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newCredentialSlot("code-54", label: "label-579")
        try item.moveTo(Staffing.CredentialSlotStatus.published)
        #expect(item.status == Staffing.CredentialSlotStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newCredentialSlot("code-54", label: "label-579")
        item.status = Staffing.CredentialSlotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialSlotStatus.created) }
    }
}
