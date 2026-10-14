@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelTargetStore = Labs.newMemoryPanelTargetStore()
        let item = Labs.newPanelTarget("code-368", title: "title-998")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
