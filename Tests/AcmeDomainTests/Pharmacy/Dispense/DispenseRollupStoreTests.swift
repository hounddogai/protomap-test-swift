@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseRollupStore = Pharmacy.newMemoryDispenseRollupStore()
        let item = Pharmacy.newDispenseRollup("code-409", name: "name-844")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
