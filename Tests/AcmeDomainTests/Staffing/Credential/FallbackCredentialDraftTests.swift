@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackCredentialDraftTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newFallbackCredentialDraft("code-65", name: "name-65")
        #expect(item.status == Staffing.FallbackCredentialDraftStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newFallbackCredentialDraft("code-65", name: "name-65")
        try item.moveTo(Staffing.FallbackCredentialDraftStatus.validated)
        #expect(item.status == Staffing.FallbackCredentialDraftStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newFallbackCredentialDraft("code-65", name: "name-65")
        item.status = Staffing.FallbackCredentialDraftStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackCredentialDraftStatus.created) }
    }
}
