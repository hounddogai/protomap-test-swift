@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLegacyDispenseEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LegacyDispenseEntryStore = Pharmacy.newMemoryLegacyDispenseEntryStore()
        let item = Pharmacy.newLegacyDispenseEntry("code-401", label: "label-68")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
