@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelOverrideStore = Labs.newMemoryPanelOverrideStore()
        let item = Labs.newPanelOverride("code-681", title: "title-144")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
