@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultCredentialMappingTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newDefaultCredentialMapping("code-123", name: "name-571")
        #expect(item.status == Staffing.DefaultCredentialMappingStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newDefaultCredentialMapping("code-123", name: "name-571")
        try item.moveTo(Staffing.DefaultCredentialMappingStatus.warming)
        #expect(item.status == Staffing.DefaultCredentialMappingStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newDefaultCredentialMapping("code-123", name: "name-571")
        item.status = Staffing.DefaultCredentialMappingStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultCredentialMappingStatus.idle) }
    }
}
