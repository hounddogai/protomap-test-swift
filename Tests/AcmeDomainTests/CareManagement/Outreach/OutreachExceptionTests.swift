@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachExceptionTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newOutreachException("code-260", title: "title-153")
        #expect(item.status == CareManagement.OutreachExceptionStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newOutreachException("code-260", title: "title-153")
        try item.moveTo(CareManagement.OutreachExceptionStatus.granted)
        #expect(item.status == CareManagement.OutreachExceptionStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newOutreachException("code-260", title: "title-153")
        item.status = CareManagement.OutreachExceptionStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachExceptionStatus.requested) }
    }
}
