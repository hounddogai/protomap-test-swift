@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRollingRecallTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RollingRecallTierStore = Pharmacy.newMemoryRollingRecallTierStore()
        let item = Pharmacy.newRollingRecallTier("code-382", name: "name-620")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
