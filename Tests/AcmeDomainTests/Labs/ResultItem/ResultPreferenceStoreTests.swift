@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultPreferenceStore = Labs.newMemoryResultPreferenceStore()
        let item = Labs.newResultPreference("code-300", title: "title-206")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
