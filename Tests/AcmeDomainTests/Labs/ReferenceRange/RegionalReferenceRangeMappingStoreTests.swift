@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRegionalReferenceRangeMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RegionalReferenceRangeMappingStore = Labs.newMemoryRegionalReferenceRangeMappingStore()
        let item = Labs.newRegionalReferenceRangeMapping("code-563", name: "name-374")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
