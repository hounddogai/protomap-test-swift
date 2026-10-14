@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRollingInteractionSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RollingInteractionSegmentStore = Pharmacy.newMemoryRollingInteractionSegmentStore()
        let item = Pharmacy.newRollingInteractionSegment("code-666", label: "label-653")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
