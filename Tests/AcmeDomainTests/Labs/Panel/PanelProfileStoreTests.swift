@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelProfileStore = Labs.newMemoryPanelProfileStore()
        let item = Labs.newPanelProfile("code-739", name: "name-541")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
