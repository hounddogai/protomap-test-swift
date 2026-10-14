@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledWitnessProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledWitnessProposalStore = Consent.newMemoryScheduledWitnessProposalStore()
        let item = Consent.newScheduledWitnessProposal("code-969", name: "name-440")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
