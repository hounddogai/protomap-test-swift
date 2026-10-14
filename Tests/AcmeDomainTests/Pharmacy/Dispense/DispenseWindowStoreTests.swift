@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseWindowStore = Pharmacy.newMemoryDispenseWindowStore()
        let item = Pharmacy.newDispenseWindow("code-116", name: "name-614")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
