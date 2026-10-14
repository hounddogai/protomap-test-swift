@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseAllocationStore = Pharmacy.newMemoryDispenseAllocationStore()
        let item = Pharmacy.newDispenseAllocation("code-526", label: "label-81")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
