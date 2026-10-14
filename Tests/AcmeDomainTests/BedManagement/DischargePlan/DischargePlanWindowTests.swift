@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanWindowTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newDischargePlanWindow("code-437", name: "name-628")
        #expect(item.status == BedManagement.DischargePlanWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newDischargePlanWindow("code-437", name: "name-628")
        try item.moveTo(BedManagement.DischargePlanWindowStatus.warming)
        #expect(item.status == BedManagement.DischargePlanWindowStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newDischargePlanWindow("code-437", name: "name-628")
        item.status = BedManagement.DischargePlanWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanWindowStatus.idle) }
    }
}
