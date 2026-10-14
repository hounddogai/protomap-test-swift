@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryWeightedAccessionMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.WeightedAccessionMappingStore = Labs.newMemoryWeightedAccessionMappingStore()
        let item = Labs.newWeightedAccessionMapping("code-835", title: "title-235")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
