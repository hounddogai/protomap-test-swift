@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPendingRecallAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PendingRecallAllocationStore = Pharmacy.newMemoryPendingRecallAllocationStore()
        let item = Pharmacy.newPendingRecallAllocation("code-741", name: "name-308")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
