@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLegacyInteractionTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LegacyInteractionTierStore = Pharmacy.newMemoryLegacyInteractionTierStore()
        let item = Pharmacy.newLegacyInteractionTier("code-533", name: "name-491")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
