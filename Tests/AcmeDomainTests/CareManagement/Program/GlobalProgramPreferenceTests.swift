@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalProgramPreferenceTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newGlobalProgramPreference("code-974", title: "title-34")
        #expect(item.status == CareManagement.GlobalProgramPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = CareManagement.newGlobalProgramPreference("code-974", title: "title-34")
        try item.moveTo(CareManagement.GlobalProgramPreferenceStatus.stopped)
        #expect(item.status == CareManagement.GlobalProgramPreferenceStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newGlobalProgramPreference("code-974", title: "title-34")
        item.status = CareManagement.GlobalProgramPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalProgramPreferenceStatus.idle) }
    }
}
