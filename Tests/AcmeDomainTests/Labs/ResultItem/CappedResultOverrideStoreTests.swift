@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedResultOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedResultOverrideStore = Labs.newMemoryCappedResultOverrideStore()
        let item = Labs.newCappedResultOverride("code-288", name: "name-799")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
