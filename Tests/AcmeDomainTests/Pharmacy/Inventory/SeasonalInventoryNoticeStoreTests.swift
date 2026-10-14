@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySeasonalInventoryNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SeasonalInventoryNoticeStore = Pharmacy.newMemorySeasonalInventoryNoticeStore()
        let item = Pharmacy.newSeasonalInventoryNotice("code-568", title: "title-990")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
