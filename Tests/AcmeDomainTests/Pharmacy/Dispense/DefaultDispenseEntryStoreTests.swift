@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultDispenseEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultDispenseEntryStore = Pharmacy.newMemoryDefaultDispenseEntryStore()
        let item = Pharmacy.newDefaultDispenseEntry("code-469", name: "name-796")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
