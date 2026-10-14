@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationVarianceTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newIsolationVariance("code-991", title: "title-732")
        #expect(item.status == BedManagement.IsolationVarianceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newIsolationVariance("code-991", title: "title-732")
        try item.moveTo(BedManagement.IsolationVarianceStatus.pending)
        #expect(item.status == BedManagement.IsolationVarianceStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newIsolationVariance("code-991", title: "title-732")
        item.status = BedManagement.IsolationVarianceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationVarianceStatus.draft) }
    }
}
