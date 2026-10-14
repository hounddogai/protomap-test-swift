@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalCredentialTargetTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newGlobalCredentialTarget("code-692", name: "name-69")
        #expect(item.status == Staffing.GlobalCredentialTargetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newGlobalCredentialTarget("code-692", name: "name-69")
        try item.moveTo(Staffing.GlobalCredentialTargetStatus.warming)
        #expect(item.status == Staffing.GlobalCredentialTargetStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newGlobalCredentialTarget("code-692", name: "name-69")
        item.status = Staffing.GlobalCredentialTargetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalCredentialTargetStatus.idle) }
    }
}
