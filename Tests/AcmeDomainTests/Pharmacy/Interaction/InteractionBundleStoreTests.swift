@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionBundleStore = Pharmacy.newMemoryInteractionBundleStore()
        let item = Pharmacy.newInteractionBundle("code-188", title: "title-541")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
