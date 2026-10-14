@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRegionalAccessionCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RegionalAccessionCheckpointStore = Labs.newMemoryRegionalAccessionCheckpointStore()
        let item = Labs.newRegionalAccessionCheckpoint("code-79", name: "name-908")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
