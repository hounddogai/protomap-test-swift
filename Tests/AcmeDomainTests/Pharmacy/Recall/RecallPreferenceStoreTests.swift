@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallPreferenceStore = Pharmacy.newMemoryRecallPreferenceStore()
        let item = Pharmacy.newRecallPreference("code-813", label: "label-409")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
