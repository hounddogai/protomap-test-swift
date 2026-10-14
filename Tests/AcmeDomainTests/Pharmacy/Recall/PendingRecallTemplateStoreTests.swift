@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPendingRecallTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PendingRecallTemplateStore = Pharmacy.newMemoryPendingRecallTemplateStore()
        let item = Pharmacy.newPendingRecallTemplate("code-13", title: "title-253")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
