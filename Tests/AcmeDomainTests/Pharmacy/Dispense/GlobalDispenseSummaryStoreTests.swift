@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryGlobalDispenseSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.GlobalDispenseSummaryStore = Pharmacy.newMemoryGlobalDispenseSummaryStore()
        let item = Pharmacy.newGlobalDispenseSummary("code-281", title: "title-721")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
