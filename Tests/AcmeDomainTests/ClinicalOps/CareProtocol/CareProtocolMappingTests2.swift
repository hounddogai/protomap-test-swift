@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolMappingTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newCareProtocolMapping("code-974", title: "title-193")
        #expect(item.status == ClinicalOps.CareProtocolMappingStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newCareProtocolMapping("code-974", title: "title-193")
        try item.moveTo(ClinicalOps.CareProtocolMappingStatus.running)
        #expect(item.status == ClinicalOps.CareProtocolMappingStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newCareProtocolMapping("code-974", title: "title-193")
        item.status = ClinicalOps.CareProtocolMappingStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolMappingStatus.new) }
    }
}
