@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalTaskOverrideTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newGlobalTaskOverride("code-174", title: "title-344")
        #expect(item.status == ClinicalOps.GlobalTaskOverrideStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = ClinicalOps.newGlobalTaskOverride("code-174", title: "title-344")
        try item.moveTo(ClinicalOps.GlobalTaskOverrideStatus.draining)
        #expect(item.status == ClinicalOps.GlobalTaskOverrideStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newGlobalTaskOverride("code-174", title: "title-344")
        item.status = ClinicalOps.GlobalTaskOverrideStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalTaskOverrideStatus.idle) }
    }
}
