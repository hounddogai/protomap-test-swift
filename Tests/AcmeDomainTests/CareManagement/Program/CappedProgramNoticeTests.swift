@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedProgramNoticeTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newCappedProgramNotice("code-646", name: "name-151")
        #expect(item.status == CareManagement.CappedProgramNoticeStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = CareManagement.newCappedProgramNotice("code-646", name: "name-151")
        try item.moveTo(CareManagement.CappedProgramNoticeStatus.failed)
        #expect(item.status == CareManagement.CappedProgramNoticeStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newCappedProgramNotice("code-646", name: "name-151")
        item.status = CareManagement.CappedProgramNoticeStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedProgramNoticeStatus.new) }
    }
}
