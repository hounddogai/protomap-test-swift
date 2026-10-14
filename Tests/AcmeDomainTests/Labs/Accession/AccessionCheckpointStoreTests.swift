@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionCheckpointStore = Labs.newMemoryAccessionCheckpointStore()
        let item = Labs.newAccessionCheckpoint("code-915", label: "label-64")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
