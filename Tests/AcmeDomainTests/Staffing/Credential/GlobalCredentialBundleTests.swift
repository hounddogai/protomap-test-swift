@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalCredentialBundleTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newGlobalCredentialBundle("code-661", name: "name-679")
        #expect(item.status == Staffing.GlobalCredentialBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newGlobalCredentialBundle("code-661", name: "name-679")
        try item.moveTo(Staffing.GlobalCredentialBundleStatus.warming)
        #expect(item.status == Staffing.GlobalCredentialBundleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newGlobalCredentialBundle("code-661", name: "name-679")
        item.status = Staffing.GlobalCredentialBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalCredentialBundleStatus.idle) }
    }
}
