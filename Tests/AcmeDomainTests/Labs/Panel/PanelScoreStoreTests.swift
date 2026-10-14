@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelScoreStore = Labs.newMemoryPanelScoreStore()
        let item = Labs.newPanelScore("code-788", title: "title-62")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
