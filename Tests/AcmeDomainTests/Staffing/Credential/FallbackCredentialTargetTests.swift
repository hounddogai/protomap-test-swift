@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackCredentialTargetTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newFallbackCredentialTarget("code-691", label: "label-367")
        #expect(item.status == Staffing.FallbackCredentialTargetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newFallbackCredentialTarget("code-691", label: "label-367")
        try item.moveTo(Staffing.FallbackCredentialTargetStatus.ready)
        #expect(item.status == Staffing.FallbackCredentialTargetStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newFallbackCredentialTarget("code-691", label: "label-367")
        item.status = Staffing.FallbackCredentialTargetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackCredentialTargetStatus.idle) }
    }
}
