@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenBudgetStore = Labs.newMemorySpecimenBudgetStore()
        let item = Labs.newSpecimenBudget("code-283", label: "label-886")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
