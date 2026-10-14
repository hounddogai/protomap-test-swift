@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenCheckpointStore = Labs.newMemorySpecimenCheckpointStore()
        let item = Labs.newSpecimenCheckpoint("code-800", label: "label-740")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
