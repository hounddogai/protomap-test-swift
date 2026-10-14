@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLegacyAccessionAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LegacyAccessionAdjustmentStore = Labs.newMemoryLegacyAccessionAdjustmentStore()
        let item = Labs.newLegacyAccessionAdjustment("code-907", name: "name-252")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
