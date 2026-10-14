@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanTierStore = Staffing.newMemoryAcuityPlanTierStore()
        let item = Staffing.newAcuityPlanTier("code-371", name: "name-66")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
