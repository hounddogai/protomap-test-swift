@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPrimaryInventoryTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PrimaryInventoryTargetStore = Pharmacy.newMemoryPrimaryInventoryTargetStore()
        let item = Pharmacy.newPrimaryInventoryTarget("code-809", name: "name-97")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
