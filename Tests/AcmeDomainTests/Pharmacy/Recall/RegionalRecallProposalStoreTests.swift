@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRegionalRecallProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RegionalRecallProposalStore = Pharmacy.newMemoryRegionalRecallProposalStore()
        let item = Pharmacy.newRegionalRecallProposal("code-558", name: "name-870")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
