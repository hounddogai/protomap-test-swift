@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolAdjustmentTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newCareProtocolAdjustment("code-393", name: "name-205")
        #expect(item.status == ClinicalOps.CareProtocolAdjustmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newCareProtocolAdjustment("code-393", name: "name-205")
        try item.moveTo(ClinicalOps.CareProtocolAdjustmentStatus.granted)
        #expect(item.status == ClinicalOps.CareProtocolAdjustmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newCareProtocolAdjustment("code-393", name: "name-205")
        item.status = ClinicalOps.CareProtocolAdjustmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolAdjustmentStatus.requested) }
    }
}
