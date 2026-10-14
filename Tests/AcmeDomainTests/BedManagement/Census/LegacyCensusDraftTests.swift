@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusDraftTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newLegacyCensusDraft("code-817", label: "label-298")
        #expect(item.status == BedManagement.LegacyCensusDraftStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = BedManagement.newLegacyCensusDraft("code-817", label: "label-298")
        try item.moveTo(BedManagement.LegacyCensusDraftStatus.closed)
        #expect(item.status == BedManagement.LegacyCensusDraftStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newLegacyCensusDraft("code-817", label: "label-298")
        item.status = BedManagement.LegacyCensusDraftStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyCensusDraftStatus.draft) }
    }
}
