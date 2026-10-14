@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallGroupStore = Pharmacy.newMemoryRecallGroupStore()
        let item = Pharmacy.newRecallGroup("code-239", name: "name-987")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
