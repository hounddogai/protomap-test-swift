@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredProxyMilestoneTests {
    @Test func startsInNew() throws {
        let item = Consent.newTieredProxyMilestone("code-4", name: "name-289")
        #expect(item.status == Consent.TieredProxyMilestoneStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newTieredProxyMilestone("code-4", name: "name-289")
        try item.moveTo(Consent.TieredProxyMilestoneStatus.queued)
        #expect(item.status == Consent.TieredProxyMilestoneStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newTieredProxyMilestone("code-4", name: "name-289")
        item.status = Consent.TieredProxyMilestoneStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.TieredProxyMilestoneStatus.new) }
    }
}
