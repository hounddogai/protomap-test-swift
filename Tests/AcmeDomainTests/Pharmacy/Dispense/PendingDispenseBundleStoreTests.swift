@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPendingDispenseBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PendingDispenseBundleStore = Pharmacy.newMemoryPendingDispenseBundleStore()
        let item = Pharmacy.newPendingDispenseBundle("code-780", name: "name-603")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
