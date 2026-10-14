@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionVarianceStore = Pharmacy.newMemoryInteractionVarianceStore()
        let item = Pharmacy.newInteractionVariance("code-18", title: "title-818")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
