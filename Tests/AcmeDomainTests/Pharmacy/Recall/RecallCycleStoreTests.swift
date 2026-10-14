@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallCycleStore = Pharmacy.newMemoryRecallCycleStore()
        let item = Pharmacy.newRecallCycle("code-490", title: "title-486")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
