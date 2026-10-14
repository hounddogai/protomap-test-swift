@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedAccessionCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedAccessionCheckpointStore = Labs.newMemoryCappedAccessionCheckpointStore()
        let item = Labs.newCappedAccessionCheckpoint("code-696", name: "name-199")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
