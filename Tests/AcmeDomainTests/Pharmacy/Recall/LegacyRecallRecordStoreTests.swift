@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLegacyRecallRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LegacyRecallRecordStore = Pharmacy.newMemoryLegacyRecallRecordStore()
        let item = Pharmacy.newLegacyRecallRecord("code-626", title: "title-254")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
