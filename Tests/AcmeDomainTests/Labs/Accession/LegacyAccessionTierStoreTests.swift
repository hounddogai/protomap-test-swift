@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLegacyAccessionTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LegacyAccessionTierStore = Labs.newMemoryLegacyAccessionTierStore()
        let item = Labs.newLegacyAccessionTier("code-61", label: "label-671")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
