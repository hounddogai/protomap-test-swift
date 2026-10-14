@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallBudgetStore = Pharmacy.newMemoryRecallBudgetStore()
        let item = Pharmacy.newRecallBudget("code-812", label: "label-665")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
