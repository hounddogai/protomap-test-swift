@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptiveSpecimenSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptiveSpecimenSnapshotStore = Labs.newMemoryAdaptiveSpecimenSnapshotStore()
        let item = Labs.newAdaptiveSpecimenSnapshot("code-770", title: "title-281")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
