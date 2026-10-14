@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCleaningThresholdTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newGlobalCleaningThreshold("code-693", label: "label-571")
        #expect(item.status == BedManagement.GlobalCleaningThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newGlobalCleaningThreshold("code-693", label: "label-571")
        try item.moveTo(BedManagement.GlobalCleaningThresholdStatus.rejected)
        #expect(item.status == BedManagement.GlobalCleaningThresholdStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newGlobalCleaningThreshold("code-693", label: "label-571")
        item.status = BedManagement.GlobalCleaningThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalCleaningThresholdStatus.proposed) }
    }
}
