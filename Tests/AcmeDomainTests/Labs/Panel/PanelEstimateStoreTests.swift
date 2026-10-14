@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelEstimateStore = Labs.newMemoryPanelEstimateStore()
        let item = Labs.newPanelEstimate("code-603", title: "title-94")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
