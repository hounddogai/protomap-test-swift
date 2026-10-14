@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLegacyPanelThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LegacyPanelThresholdStore = Labs.newMemoryLegacyPanelThresholdStore()
        let item = Labs.newLegacyPanelThreshold("code-758", title: "title-623")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
