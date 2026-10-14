@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessMilestoneTests {
    @Test func startsInProposed() throws {
        let item = Consent.newWitnessMilestone("code-467", title: "title-526")
        #expect(item.status == Consent.WitnessMilestoneStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newWitnessMilestone("code-467", title: "title-526")
        try item.moveTo(Consent.WitnessMilestoneStatus.rejected)
        #expect(item.status == Consent.WitnessMilestoneStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newWitnessMilestone("code-467", title: "title-526")
        item.status = Consent.WitnessMilestoneStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessMilestoneStatus.proposed) }
    }
}
