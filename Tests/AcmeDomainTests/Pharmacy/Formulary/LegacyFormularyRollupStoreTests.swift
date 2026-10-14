@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLegacyFormularyRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LegacyFormularyRollupStore = Pharmacy.newMemoryLegacyFormularyRollupStore()
        let item = Pharmacy.newLegacyFormularyRollup("code-934", label: "label-599")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
