@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryCappedWitnessProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.CappedWitnessProposalStore = Consent.newMemoryCappedWitnessProposalStore()
        let item = Consent.newCappedWitnessProposal("code-169", name: "name-586")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
