@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseEntryStore = Pharmacy.newMemoryDispenseEntryStore()
        let item = Pharmacy.newDispenseEntry("code-719", title: "title-668")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
