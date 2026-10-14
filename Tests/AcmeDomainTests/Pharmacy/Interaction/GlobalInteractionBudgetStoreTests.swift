@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryGlobalInteractionBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.GlobalInteractionBudgetStore = Pharmacy.newMemoryGlobalInteractionBudgetStore()
        let item = Pharmacy.newGlobalInteractionBudget("code-49", name: "name-881")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
