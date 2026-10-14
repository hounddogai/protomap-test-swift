@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultAlertProfileTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newDefaultAlertProfile("code-637", title: "title-372")
        #expect(item.status == ClinicalOps.DefaultAlertProfileStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newDefaultAlertProfile("code-637", title: "title-372")
        try item.moveTo(ClinicalOps.DefaultAlertProfileStatus.warming)
        #expect(item.status == ClinicalOps.DefaultAlertProfileStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newDefaultAlertProfile("code-637", title: "title-372")
        item.status = ClinicalOps.DefaultAlertProfileStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultAlertProfileStatus.idle) }
    }
}
