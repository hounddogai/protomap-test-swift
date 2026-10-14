@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackCareProtocolProfileTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newFallbackCareProtocolProfile("code-684", name: "name-337")
        #expect(item.status == ClinicalOps.FallbackCareProtocolProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newFallbackCareProtocolProfile("code-684", name: "name-337")
        try item.moveTo(ClinicalOps.FallbackCareProtocolProfileStatus.suspended)
        #expect(item.status == ClinicalOps.FallbackCareProtocolProfileStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newFallbackCareProtocolProfile("code-684", name: "name-337")
        item.status = ClinicalOps.FallbackCareProtocolProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackCareProtocolProfileStatus.draft) }
    }
}
