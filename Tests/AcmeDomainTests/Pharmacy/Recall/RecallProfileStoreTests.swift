@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallProfileStore = Pharmacy.newMemoryRecallProfileStore()
        let item = Pharmacy.newRecallProfile("code-636", name: "name-777")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
