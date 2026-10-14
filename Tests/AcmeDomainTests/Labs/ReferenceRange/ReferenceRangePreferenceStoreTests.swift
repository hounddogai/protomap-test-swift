@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangePreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangePreferenceStore = Labs.newMemoryReferenceRangePreferenceStore()
        let item = Labs.newReferenceRangePreference("code-481", title: "title-919")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
