@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultInteractionProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultInteractionProfileStore = Pharmacy.newMemoryDefaultInteractionProfileStore()
        let item = Pharmacy.newDefaultInteractionProfile("code-210", name: "name-598")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
