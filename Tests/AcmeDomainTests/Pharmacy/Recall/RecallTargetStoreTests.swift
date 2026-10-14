@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallTargetStore = Pharmacy.newMemoryRecallTargetStore()
        let item = Pharmacy.newRecallTarget("code-785", name: "name-235")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
