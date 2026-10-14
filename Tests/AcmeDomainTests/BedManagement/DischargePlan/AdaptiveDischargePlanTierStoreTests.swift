@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryAdaptiveDischargePlanTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.AdaptiveDischargePlanTierStore = BedManagement.newMemoryAdaptiveDischargePlanTierStore()
        let item = BedManagement.newAdaptiveDischargePlanTier("code-170", name: "name-873")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
