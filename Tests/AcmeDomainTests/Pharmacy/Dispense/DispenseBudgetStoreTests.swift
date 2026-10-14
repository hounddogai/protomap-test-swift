@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseBudgetStore = Pharmacy.newMemoryDispenseBudgetStore()
        let item = Pharmacy.newDispenseBudget("code-220", name: "name-56")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
