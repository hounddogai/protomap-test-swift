@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseDraftStore = Pharmacy.newMemoryDispenseDraftStore()
        let item = Pharmacy.newDispenseDraft("code-971", label: "label-720")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
