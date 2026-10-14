@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPendingInteractionAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PendingInteractionAllocationStore = Pharmacy.newMemoryPendingInteractionAllocationStore()
        let item = Pharmacy.newPendingInteractionAllocation("code-109", label: "label-365")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
