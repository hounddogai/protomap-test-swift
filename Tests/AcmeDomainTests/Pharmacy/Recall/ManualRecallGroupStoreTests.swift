@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryManualRecallGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ManualRecallGroupStore = Pharmacy.newMemoryManualRecallGroupStore()
        let item = Pharmacy.newManualRecallGroup("code-230", name: "name-961")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
