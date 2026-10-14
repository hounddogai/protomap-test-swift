@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramMetricTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newProgramMetric("code-554", title: "title-599")
        #expect(item.status == CareManagement.ProgramMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newProgramMetric("code-554", title: "title-599")
        try item.moveTo(CareManagement.ProgramMetricStatus.warming)
        #expect(item.status == CareManagement.ProgramMetricStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newProgramMetric("code-554", title: "title-599")
        item.status = CareManagement.ProgramMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramMetricStatus.idle) }
    }
}
