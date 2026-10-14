@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryAdaptiveInventoryNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.AdaptiveInventoryNoticeStore = Pharmacy.newMemoryAdaptiveInventoryNoticeStore()
        let item = Pharmacy.newAdaptiveInventoryNotice("code-584", title: "title-470")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
