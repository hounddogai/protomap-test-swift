@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallDigestStore = Pharmacy.newMemoryRecallDigestStore()
        let item = Pharmacy.newRecallDigest("code-9", title: "title-239")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
