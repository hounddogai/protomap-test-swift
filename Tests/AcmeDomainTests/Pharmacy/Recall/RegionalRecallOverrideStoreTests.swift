@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRegionalRecallOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RegionalRecallOverrideStore = Pharmacy.newMemoryRegionalRecallOverrideStore()
        let item = Pharmacy.newRegionalRecallOverride("code-610", label: "label-393")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
