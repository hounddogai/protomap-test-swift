@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRollingInteractionWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RollingInteractionWindowStore = Pharmacy.newMemoryRollingInteractionWindowStore()
        let item = Pharmacy.newRollingInteractionWindow("code-629", title: "title-185")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
