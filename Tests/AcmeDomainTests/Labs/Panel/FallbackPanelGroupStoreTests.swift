@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackPanelGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackPanelGroupStore = Labs.newMemoryFallbackPanelGroupStore()
        let item = Labs.newFallbackPanelGroup("code-296", name: "name-977")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
