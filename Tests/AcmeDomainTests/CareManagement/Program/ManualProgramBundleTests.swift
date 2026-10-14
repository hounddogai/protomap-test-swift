@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualProgramBundleTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newManualProgramBundle("code-539", title: "title-162")
        #expect(item.status == CareManagement.ManualProgramBundleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newManualProgramBundle("code-539", title: "title-162")
        try item.moveTo(CareManagement.ManualProgramBundleStatus.running)
        #expect(item.status == CareManagement.ManualProgramBundleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newManualProgramBundle("code-539", title: "title-162")
        item.status = CareManagement.ManualProgramBundleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualProgramBundleStatus.new) }
    }
}
