@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionSummaryStore = Pharmacy.newMemorySubstitutionSummaryStore()
        let item = Pharmacy.newSubstitutionSummary("code-629", name: "name-444")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
