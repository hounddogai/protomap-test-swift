@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryStrictInventoryProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.StrictInventoryProposalStore = Pharmacy.newMemoryStrictInventoryProposalStore()
        let item = Pharmacy.newStrictInventoryProposal("code-180", label: "label-561")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
