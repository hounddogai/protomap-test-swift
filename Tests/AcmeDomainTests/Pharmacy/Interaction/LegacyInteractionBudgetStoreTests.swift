@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLegacyInteractionBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LegacyInteractionBudgetStore = Pharmacy.newMemoryLegacyInteractionBudgetStore()
        let item = Pharmacy.newLegacyInteractionBudget("code-58", name: "name-755")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
