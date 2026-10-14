@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientDisclosureMilestoneTests {
    @Test func startsInDraft() throws {
        let item = Consent.newLenientDisclosureMilestone("code-998", label: "label-611")
        #expect(item.status == Consent.LenientDisclosureMilestoneStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Consent.newLenientDisclosureMilestone("code-998", label: "label-611")
        try item.moveTo(Consent.LenientDisclosureMilestoneStatus.suspended)
        #expect(item.status == Consent.LenientDisclosureMilestoneStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newLenientDisclosureMilestone("code-998", label: "label-611")
        item.status = Consent.LenientDisclosureMilestoneStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientDisclosureMilestoneStatus.draft) }
    }
}
