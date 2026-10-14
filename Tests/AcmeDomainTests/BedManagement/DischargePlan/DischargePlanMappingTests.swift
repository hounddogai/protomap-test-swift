@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanMappingTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newDischargePlanMapping("code-512", label: "label-43")
        #expect(item.status == BedManagement.DischargePlanMappingStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newDischargePlanMapping("code-512", label: "label-43")
        try item.moveTo(BedManagement.DischargePlanMappingStatus.warming)
        #expect(item.status == BedManagement.DischargePlanMappingStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newDischargePlanMapping("code-512", label: "label-43")
        item.status = BedManagement.DischargePlanMappingStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanMappingStatus.idle) }
    }
}
