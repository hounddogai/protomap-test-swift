@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureMilestoneTests {
    @Test func startsInNew() throws {
        let item = Consent.newDisclosureMilestone("code-262", label: "label-890")
        #expect(item.status == Consent.DisclosureMilestoneStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newDisclosureMilestone("code-262", label: "label-890")
        try item.moveTo(Consent.DisclosureMilestoneStatus.queued)
        #expect(item.status == Consent.DisclosureMilestoneStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newDisclosureMilestone("code-262", label: "label-890")
        item.status = Consent.DisclosureMilestoneStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureMilestoneStatus.new) }
    }
}
