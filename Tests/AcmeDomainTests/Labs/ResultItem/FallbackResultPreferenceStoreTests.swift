@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackResultPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackResultPreferenceStore = Labs.newMemoryFallbackResultPreferenceStore()
        let item = Labs.newFallbackResultPreference("code-736", title: "title-424")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
