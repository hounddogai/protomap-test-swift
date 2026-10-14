@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPendingResultPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PendingResultPreferenceStore = Labs.newMemoryPendingResultPreferenceStore()
        let item = Labs.newPendingResultPreference("code-48", label: "label-230")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
