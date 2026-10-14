@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenBatchStore = Labs.newMemorySpecimenBatchStore()
        let item = Labs.newSpecimenBatch("code-175", label: "label-34")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
