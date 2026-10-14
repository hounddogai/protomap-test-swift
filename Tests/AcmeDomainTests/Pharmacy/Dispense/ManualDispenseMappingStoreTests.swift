@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryManualDispenseMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ManualDispenseMappingStore = Pharmacy.newMemoryManualDispenseMappingStore()
        let item = Pharmacy.newManualDispenseMapping("code-701", label: "label-317")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
