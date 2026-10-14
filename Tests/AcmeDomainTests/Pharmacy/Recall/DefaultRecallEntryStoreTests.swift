@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultRecallEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultRecallEntryStore = Pharmacy.newMemoryDefaultRecallEntryStore()
        let item = Pharmacy.newDefaultRecallEntry("code-585", name: "name-93")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
