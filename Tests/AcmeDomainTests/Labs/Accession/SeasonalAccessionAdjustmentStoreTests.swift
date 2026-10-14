@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySeasonalAccessionAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SeasonalAccessionAdjustmentStore = Labs.newMemorySeasonalAccessionAdjustmentStore()
        let item = Labs.newSeasonalAccessionAdjustment("code-708", name: "name-760")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
