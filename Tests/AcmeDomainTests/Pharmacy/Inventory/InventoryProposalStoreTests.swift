@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryProposalStore = Pharmacy.newMemoryInventoryProposalStore()
        let item = Pharmacy.newInventoryProposal("code-748", label: "label-343")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
