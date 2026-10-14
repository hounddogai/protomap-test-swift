@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredShiftBundleTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newTieredShiftBundle("code-311", title: "title-572")
        #expect(item.status == Staffing.TieredShiftBundleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Staffing.newTieredShiftBundle("code-311", title: "title-572")
        try item.moveTo(Staffing.TieredShiftBundleStatus.closed)
        #expect(item.status == Staffing.TieredShiftBundleStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newTieredShiftBundle("code-311", title: "title-572")
        item.status = Staffing.TieredShiftBundleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredShiftBundleStatus.draft) }
    }
}
