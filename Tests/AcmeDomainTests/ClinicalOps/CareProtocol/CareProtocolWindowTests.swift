@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolWindowTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newCareProtocolWindow("code-812", title: "title-319")
        #expect(item.status == ClinicalOps.CareProtocolWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = ClinicalOps.newCareProtocolWindow("code-812", title: "title-319")
        try item.moveTo(ClinicalOps.CareProtocolWindowStatus.ready)
        #expect(item.status == ClinicalOps.CareProtocolWindowStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newCareProtocolWindow("code-812", title: "title-319")
        item.status = ClinicalOps.CareProtocolWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolWindowStatus.idle) }
    }
}
