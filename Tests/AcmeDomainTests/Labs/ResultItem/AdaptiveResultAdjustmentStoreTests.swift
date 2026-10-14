@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptiveResultAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptiveResultAdjustmentStore = Labs.newMemoryAdaptiveResultAdjustmentStore()
        let item = Labs.newAdaptiveResultAdjustment("code-361", label: "label-189")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
