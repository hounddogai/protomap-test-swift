@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseGroupStore = Pharmacy.newMemoryDispenseGroupStore()
        let item = Pharmacy.newDispenseGroup("code-856", name: "name-821")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
