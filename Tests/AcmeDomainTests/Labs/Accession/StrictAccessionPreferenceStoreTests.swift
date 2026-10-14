@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryStrictAccessionPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.StrictAccessionPreferenceStore = Labs.newMemoryStrictAccessionPreferenceStore()
        let item = Labs.newStrictAccessionPreference("code-6", label: "label-39")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
