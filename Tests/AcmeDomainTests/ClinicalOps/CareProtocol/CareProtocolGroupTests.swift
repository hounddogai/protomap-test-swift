@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolGroupTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newCareProtocolGroup("code-34", label: "label-110")
        #expect(item.status == ClinicalOps.CareProtocolGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newCareProtocolGroup("code-34", label: "label-110")
        try item.moveTo(ClinicalOps.CareProtocolGroupStatus.running)
        #expect(item.status == ClinicalOps.CareProtocolGroupStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newCareProtocolGroup("code-34", label: "label-110")
        item.status = ClinicalOps.CareProtocolGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolGroupStatus.new) }
    }
}
