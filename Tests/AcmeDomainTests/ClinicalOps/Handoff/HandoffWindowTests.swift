@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffWindowTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newHandoffWindow("code-942", label: "label-800")
        #expect(item.status == ClinicalOps.HandoffWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = ClinicalOps.newHandoffWindow("code-942", label: "label-800")
        try item.moveTo(ClinicalOps.HandoffWindowStatus.draining)
        #expect(item.status == ClinicalOps.HandoffWindowStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newHandoffWindow("code-942", label: "label-800")
        item.status = ClinicalOps.HandoffWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffWindowStatus.idle) }
    }
}
