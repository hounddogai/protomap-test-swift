@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanOverrideTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newDischargePlanOverride("code-728", name: "name-540")
        #expect(item.status == BedManagement.DischargePlanOverrideStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = BedManagement.newDischargePlanOverride("code-728", name: "name-540")
        try item.moveTo(BedManagement.DischargePlanOverrideStatus.done)
        #expect(item.status == BedManagement.DischargePlanOverrideStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newDischargePlanOverride("code-728", name: "name-540")
        item.status = BedManagement.DischargePlanOverrideStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanOverrideStatus.new) }
    }
}
