@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanThresholdTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newDischargePlanThreshold("code-358", name: "name-269")
        #expect(item.status == BedManagement.DischargePlanThresholdStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newDischargePlanThreshold("code-358", name: "name-269")
        try item.moveTo(BedManagement.DischargePlanThresholdStatus.validated)
        #expect(item.status == BedManagement.DischargePlanThresholdStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newDischargePlanThreshold("code-358", name: "name-269")
        item.status = BedManagement.DischargePlanThresholdStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanThresholdStatus.created) }
    }
}
