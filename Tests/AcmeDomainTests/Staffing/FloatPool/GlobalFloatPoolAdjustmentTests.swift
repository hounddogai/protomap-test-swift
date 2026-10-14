@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalFloatPoolAdjustmentTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newGlobalFloatPoolAdjustment("code-289", label: "label-63")
        #expect(item.status == Staffing.GlobalFloatPoolAdjustmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newGlobalFloatPoolAdjustment("code-289", label: "label-63")
        try item.moveTo(Staffing.GlobalFloatPoolAdjustmentStatus.active)
        #expect(item.status == Staffing.GlobalFloatPoolAdjustmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newGlobalFloatPoolAdjustment("code-289", label: "label-63")
        item.status = Staffing.GlobalFloatPoolAdjustmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalFloatPoolAdjustmentStatus.draft) }
    }
}
