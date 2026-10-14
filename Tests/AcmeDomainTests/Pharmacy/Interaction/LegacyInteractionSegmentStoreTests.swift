@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLegacyInteractionSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LegacyInteractionSegmentStore = Pharmacy.newMemoryLegacyInteractionSegmentStore()
        let item = Pharmacy.newLegacyInteractionSegment("code-562", label: "label-238")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
