@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackResultProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackResultProfileStore = Labs.newMemoryFallbackResultProfileStore()
        let item = Labs.newFallbackResultProfile("code-828", title: "title-478")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
