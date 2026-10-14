@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredProgramPreferenceTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newTieredProgramPreference("code-129", name: "name-745")
        #expect(item.status == CareManagement.TieredProgramPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = CareManagement.newTieredProgramPreference("code-129", name: "name-745")
        try item.moveTo(CareManagement.TieredProgramPreferenceStatus.stopped)
        #expect(item.status == CareManagement.TieredProgramPreferenceStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newTieredProgramPreference("code-129", name: "name-745")
        item.status = CareManagement.TieredProgramPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredProgramPreferenceStatus.idle) }
    }
}
