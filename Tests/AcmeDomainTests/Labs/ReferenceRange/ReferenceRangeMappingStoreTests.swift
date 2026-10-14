@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeMappingStore = Labs.newMemoryReferenceRangeMappingStore()
        let item = Labs.newReferenceRangeMapping("code-343", name: "name-158")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
