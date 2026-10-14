@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeThresholdStore = Labs.newMemoryReferenceRangeThresholdStore()
        let item = Labs.newReferenceRangeThreshold("code-461", name: "name-678")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
