@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalCareGapNoticeTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newGlobalCareGapNotice("code-694", name: "name-551")
        #expect(item.status == CareManagement.GlobalCareGapNoticeStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newGlobalCareGapNotice("code-694", name: "name-551")
        try item.moveTo(CareManagement.GlobalCareGapNoticeStatus.granted)
        #expect(item.status == CareManagement.GlobalCareGapNoticeStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newGlobalCareGapNotice("code-694", name: "name-551")
        item.status = CareManagement.GlobalCareGapNoticeStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalCareGapNoticeStatus.requested) }
    }
}
