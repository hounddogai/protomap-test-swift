@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelSummaryStore = Labs.newMemoryPanelSummaryStore()
        let item = Labs.newPanelSummary("code-215", label: "label-40")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
