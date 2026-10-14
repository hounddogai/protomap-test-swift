@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalWitnessCycleTests {
    @Test func startsInProposed() throws {
        let item = Consent.newSeasonalWitnessCycle("code-520", name: "name-232")
        #expect(item.status == Consent.SeasonalWitnessCycleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newSeasonalWitnessCycle("code-520", name: "name-232")
        try item.moveTo(Consent.SeasonalWitnessCycleStatus.approved)
        #expect(item.status == Consent.SeasonalWitnessCycleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newSeasonalWitnessCycle("code-520", name: "name-232")
        item.status = Consent.SeasonalWitnessCycleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.SeasonalWitnessCycleStatus.proposed) }
    }
}
