@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelMappingStore = Labs.newMemoryPanelMappingStore()
        let item = Labs.newPanelMapping("code-653", name: "name-310")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
