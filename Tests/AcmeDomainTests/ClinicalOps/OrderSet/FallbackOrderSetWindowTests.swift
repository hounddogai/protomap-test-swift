@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackOrderSetWindowTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newFallbackOrderSetWindow("code-892", label: "label-414")
        #expect(item.status == ClinicalOps.FallbackOrderSetWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newFallbackOrderSetWindow("code-892", label: "label-414")
        try item.moveTo(ClinicalOps.FallbackOrderSetWindowStatus.warming)
        #expect(item.status == ClinicalOps.FallbackOrderSetWindowStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newFallbackOrderSetWindow("code-892", label: "label-414")
        item.status = ClinicalOps.FallbackOrderSetWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackOrderSetWindowStatus.idle) }
    }
}
