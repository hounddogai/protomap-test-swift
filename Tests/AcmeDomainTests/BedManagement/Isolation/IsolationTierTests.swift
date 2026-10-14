@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationTierTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newIsolationTier("code-842", name: "name-655")
        #expect(item.status == BedManagement.IsolationTierStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newIsolationTier("code-842", name: "name-655")
        try item.moveTo(BedManagement.IsolationTierStatus.active)
        #expect(item.status == BedManagement.IsolationTierStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newIsolationTier("code-842", name: "name-655")
        item.status = BedManagement.IsolationTierStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationTierStatus.draft) }
    }
}
