@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionSummaryStore = Pharmacy.newMemoryInteractionSummaryStore()
        let item = Pharmacy.newInteractionSummary("code-856", title: "title-450")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
