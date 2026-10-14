@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLegacyAccessionThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LegacyAccessionThresholdStore = Labs.newMemoryLegacyAccessionThresholdStore()
        let item = Labs.newLegacyAccessionThreshold("code-57", label: "label-584")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
