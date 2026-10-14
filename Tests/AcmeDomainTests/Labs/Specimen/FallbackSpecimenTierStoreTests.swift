@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackSpecimenTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackSpecimenTierStore = Labs.newMemoryFallbackSpecimenTierStore()
        let item = Labs.newFallbackSpecimenTier("code-839", name: "name-911")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
