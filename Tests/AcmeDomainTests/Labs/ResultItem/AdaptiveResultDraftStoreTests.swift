@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptiveResultDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptiveResultDraftStore = Labs.newMemoryAdaptiveResultDraftStore()
        let item = Labs.newAdaptiveResultDraft("code-913", name: "name-856")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
