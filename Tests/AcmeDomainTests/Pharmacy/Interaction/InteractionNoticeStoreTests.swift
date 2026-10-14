@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionNoticeStore = Pharmacy.newMemoryInteractionNoticeStore()
        let item = Pharmacy.newInteractionNotice("code-380", label: "label-352")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
