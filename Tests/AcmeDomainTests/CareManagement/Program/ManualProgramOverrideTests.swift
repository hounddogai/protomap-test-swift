@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualProgramOverrideTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newManualProgramOverride("code-602", name: "name-260")
        #expect(item.status == CareManagement.ManualProgramOverrideStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newManualProgramOverride("code-602", name: "name-260")
        try item.moveTo(CareManagement.ManualProgramOverrideStatus.warming)
        #expect(item.status == CareManagement.ManualProgramOverrideStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newManualProgramOverride("code-602", name: "name-260")
        item.status = CareManagement.ManualProgramOverrideStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualProgramOverrideStatus.idle) }
    }
}
