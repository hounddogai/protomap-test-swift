@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelWindowStore = Labs.newMemoryPanelWindowStore()
        let item = Labs.newPanelWindow("code-648", name: "name-974")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
