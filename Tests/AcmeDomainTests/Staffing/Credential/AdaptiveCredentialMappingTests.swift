@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveCredentialMappingTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newAdaptiveCredentialMapping("code-973", label: "label-790")
        #expect(item.status == Staffing.AdaptiveCredentialMappingStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newAdaptiveCredentialMapping("code-973", label: "label-790")
        try item.moveTo(Staffing.AdaptiveCredentialMappingStatus.rejected)
        #expect(item.status == Staffing.AdaptiveCredentialMappingStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newAdaptiveCredentialMapping("code-973", label: "label-790")
        item.status = Staffing.AdaptiveCredentialMappingStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AdaptiveCredentialMappingStatus.proposed) }
    }
}
