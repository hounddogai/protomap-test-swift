@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptiveSpecimenBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptiveSpecimenBatchStore = Labs.newMemoryAdaptiveSpecimenBatchStore()
        let item = Labs.newAdaptiveSpecimenBatch("code-776", name: "name-827")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
