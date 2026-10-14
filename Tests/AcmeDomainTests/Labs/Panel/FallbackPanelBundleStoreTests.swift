@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackPanelBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackPanelBundleStore = Labs.newMemoryFallbackPanelBundleStore()
        let item = Labs.newFallbackPanelBundle("code-371", name: "name-46")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
