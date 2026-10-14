@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackCredentialWindowTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newFallbackCredentialWindow("code-205", label: "label-365")
        #expect(item.status == Staffing.FallbackCredentialWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newFallbackCredentialWindow("code-205", label: "label-365")
        try item.moveTo(Staffing.FallbackCredentialWindowStatus.resolved)
        #expect(item.status == Staffing.FallbackCredentialWindowStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newFallbackCredentialWindow("code-205", label: "label-365")
        item.status = Staffing.FallbackCredentialWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackCredentialWindowStatus.`open`) }
    }
}
