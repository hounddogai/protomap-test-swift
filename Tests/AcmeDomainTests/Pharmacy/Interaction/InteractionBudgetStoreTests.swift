@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionBudgetStore = Pharmacy.newMemoryInteractionBudgetStore()
        let item = Pharmacy.newInteractionBudget("code-966", title: "title-869")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
