@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryManualCourierEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ManualCourierEntryStore = Labs.newMemoryManualCourierEntryStore()
        let item = Labs.newManualCourierEntry("code-392", name: "name-914")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
