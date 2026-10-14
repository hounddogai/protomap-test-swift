@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseNoticeStore = Pharmacy.newMemoryDispenseNoticeStore()
        let item = Pharmacy.newDispenseNotice("code-691", title: "title-852")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
