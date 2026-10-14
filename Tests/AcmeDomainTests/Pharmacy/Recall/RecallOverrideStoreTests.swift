@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallOverrideStore = Pharmacy.newMemoryRecallOverrideStore()
        let item = Pharmacy.newRecallOverride("code-650", name: "name-847")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
