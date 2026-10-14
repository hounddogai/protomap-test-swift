@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryTieredDispenseNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.TieredDispenseNoticeStore = Pharmacy.newMemoryTieredDispenseNoticeStore()
        let item = Pharmacy.newTieredDispenseNotice("code-553", name: "name-335")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
