@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryTieredFormularyRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.TieredFormularyRollupStore = Pharmacy.newMemoryTieredFormularyRollupStore()
        let item = Pharmacy.newTieredFormularyRollup("code-141", name: "name-424")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
