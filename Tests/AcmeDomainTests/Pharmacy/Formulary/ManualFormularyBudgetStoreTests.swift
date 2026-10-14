@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryManualFormularyBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ManualFormularyBudgetStore = Pharmacy.newMemoryManualFormularyBudgetStore()
        let item = Pharmacy.newManualFormularyBudget("code-78", title: "title-103")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
