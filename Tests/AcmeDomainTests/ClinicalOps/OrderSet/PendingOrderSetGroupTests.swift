@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingOrderSetGroupTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newPendingOrderSetGroup("code-106", label: "label-208")
        #expect(item.status == ClinicalOps.PendingOrderSetGroupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newPendingOrderSetGroup("code-106", label: "label-208")
        try item.moveTo(ClinicalOps.PendingOrderSetGroupStatus.warming)
        #expect(item.status == ClinicalOps.PendingOrderSetGroupStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newPendingOrderSetGroup("code-106", label: "label-208")
        item.status = ClinicalOps.PendingOrderSetGroupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingOrderSetGroupStatus.idle) }
    }
}
