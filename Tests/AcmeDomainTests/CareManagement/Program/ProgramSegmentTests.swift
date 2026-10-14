@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramSegmentTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newProgramSegment("code-272", name: "name-605")
        #expect(item.status == CareManagement.ProgramSegmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newProgramSegment("code-272", name: "name-605")
        try item.moveTo(CareManagement.ProgramSegmentStatus.warming)
        #expect(item.status == CareManagement.ProgramSegmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newProgramSegment("code-272", name: "name-605")
        item.status = CareManagement.ProgramSegmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramSegmentStatus.idle) }
    }
}
