@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryStrictFormularyAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.StrictFormularyAllocationStore = Pharmacy.newMemoryStrictFormularyAllocationStore()
        let item = Pharmacy.newStrictFormularyAllocation("code-104", label: "label-484")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
