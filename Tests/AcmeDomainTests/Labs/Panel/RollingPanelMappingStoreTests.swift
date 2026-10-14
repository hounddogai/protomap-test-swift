@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRollingPanelMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RollingPanelMappingStore = Labs.newMemoryRollingPanelMappingStore()
        let item = Labs.newRollingPanelMapping("code-323", label: "label-282")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
