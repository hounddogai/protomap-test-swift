@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCleaningVarianceTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newGlobalCleaningVariance("code-973", label: "label-333")
        #expect(item.status == BedManagement.GlobalCleaningVarianceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newGlobalCleaningVariance("code-973", label: "label-333")
        try item.moveTo(BedManagement.GlobalCleaningVarianceStatus.approved)
        #expect(item.status == BedManagement.GlobalCleaningVarianceStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newGlobalCleaningVariance("code-973", label: "label-333")
        item.status = BedManagement.GlobalCleaningVarianceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalCleaningVarianceStatus.proposed) }
    }
}
