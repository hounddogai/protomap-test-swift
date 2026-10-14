@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseRecordStore = Pharmacy.newMemoryDispenseRecordStore()
        let item = Pharmacy.newDispenseRecord("code-8", name: "name-207")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
