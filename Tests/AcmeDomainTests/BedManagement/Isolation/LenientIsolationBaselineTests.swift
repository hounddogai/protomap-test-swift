@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientIsolationBaselineTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newLenientIsolationBaseline("code-43", label: "label-106")
        #expect(item.status == BedManagement.LenientIsolationBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newLenientIsolationBaseline("code-43", label: "label-106")
        try item.moveTo(BedManagement.LenientIsolationBaselineStatus.resolved)
        #expect(item.status == BedManagement.LenientIsolationBaselineStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newLenientIsolationBaseline("code-43", label: "label-106")
        item.status = BedManagement.LenientIsolationBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientIsolationBaselineStatus.`open`) }
    }
}
