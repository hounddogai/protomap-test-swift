@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRegionalInteractionWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RegionalInteractionWindowStore = Pharmacy.newMemoryRegionalInteractionWindowStore()
        let item = Pharmacy.newRegionalInteractionWindow("code-907", title: "title-157")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
