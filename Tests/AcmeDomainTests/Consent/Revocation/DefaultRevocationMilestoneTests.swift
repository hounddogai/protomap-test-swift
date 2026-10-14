@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultRevocationMilestoneTests {
    @Test func startsInRequested() throws {
        let item = Consent.newDefaultRevocationMilestone("code-672", title: "title-340")
        #expect(item.status == Consent.DefaultRevocationMilestoneStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newDefaultRevocationMilestone("code-672", title: "title-340")
        try item.moveTo(Consent.DefaultRevocationMilestoneStatus.granted)
        #expect(item.status == Consent.DefaultRevocationMilestoneStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newDefaultRevocationMilestone("code-672", title: "title-340")
        item.status = Consent.DefaultRevocationMilestoneStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DefaultRevocationMilestoneStatus.requested) }
    }
}
