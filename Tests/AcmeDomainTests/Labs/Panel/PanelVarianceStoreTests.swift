@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelVarianceStore = Labs.newMemoryPanelVarianceStore()
        let item = Labs.newPanelVariance("code-997", label: "label-44")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
