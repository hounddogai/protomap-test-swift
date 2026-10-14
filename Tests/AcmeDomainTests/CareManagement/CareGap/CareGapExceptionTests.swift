@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapExceptionTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newCareGapException("code-500", title: "title-694")
        #expect(item.status == CareManagement.CareGapExceptionStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newCareGapException("code-500", title: "title-694")
        try item.moveTo(CareManagement.CareGapExceptionStatus.active)
        #expect(item.status == CareManagement.CareGapExceptionStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newCareGapException("code-500", title: "title-694")
        item.status = CareManagement.CareGapExceptionStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapExceptionStatus.draft) }
    }
}
