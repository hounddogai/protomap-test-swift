@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanOverrideStore = Staffing.newMemoryAcuityPlanOverrideStore()
        let item = Staffing.newAcuityPlanOverride("code-881", title: "title-710")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
