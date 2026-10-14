@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualCredentialMappingTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newManualCredentialMapping("code-887", name: "name-814")
        #expect(item.status == Staffing.ManualCredentialMappingStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newManualCredentialMapping("code-887", name: "name-814")
        try item.moveTo(Staffing.ManualCredentialMappingStatus.revoked)
        #expect(item.status == Staffing.ManualCredentialMappingStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newManualCredentialMapping("code-887", name: "name-814")
        item.status = Staffing.ManualCredentialMappingStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ManualCredentialMappingStatus.requested) }
    }
}
