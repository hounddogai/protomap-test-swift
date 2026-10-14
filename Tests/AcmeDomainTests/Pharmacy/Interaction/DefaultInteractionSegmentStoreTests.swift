@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultInteractionSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultInteractionSegmentStore = Pharmacy.newMemoryDefaultInteractionSegmentStore()
        let item = Pharmacy.newDefaultInteractionSegment("code-763", title: "title-398")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
