@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallNoticeStore = Pharmacy.newMemoryRecallNoticeStore()
        let item = Pharmacy.newRecallNotice("code-967", title: "title-490")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
