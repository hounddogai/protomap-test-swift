@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultCheckpointStore = Labs.newMemoryResultCheckpointStore()
        let item = Labs.newResultCheckpoint("code-146", name: "name-395")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
