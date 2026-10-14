@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeAdjustmentStore = Labs.newMemoryReferenceRangeAdjustmentStore()
        let item = Labs.newReferenceRangeAdjustment("code-525", label: "label-381")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
