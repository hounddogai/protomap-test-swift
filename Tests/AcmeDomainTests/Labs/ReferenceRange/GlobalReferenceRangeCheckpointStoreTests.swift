@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryGlobalReferenceRangeCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.GlobalReferenceRangeCheckpointStore = Labs.newMemoryGlobalReferenceRangeCheckpointStore()
        let item = Labs.newGlobalReferenceRangeCheckpoint("code-635", name: "name-669")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
