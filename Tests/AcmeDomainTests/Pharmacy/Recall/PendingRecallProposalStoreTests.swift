@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPendingRecallProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PendingRecallProposalStore = Pharmacy.newMemoryPendingRecallProposalStore()
        let item = Pharmacy.newPendingRecallProposal("code-62", title: "title-131")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
