@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptivePanelEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptivePanelEstimateStore = Labs.newMemoryAdaptivePanelEstimateStore()
        let item = Labs.newAdaptivePanelEstimate("code-687", label: "label-306")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
