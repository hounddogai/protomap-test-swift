@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallSegmentStore = Pharmacy.newMemoryRecallSegmentStore()
        let item = Pharmacy.newRecallSegment("code-168", name: "name-681")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
