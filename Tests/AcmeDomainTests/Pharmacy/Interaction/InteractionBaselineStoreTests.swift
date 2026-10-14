@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionBaselineStore = Pharmacy.newMemoryInteractionBaselineStore()
        let item = Pharmacy.newInteractionBaseline("code-666", label: "label-187")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
