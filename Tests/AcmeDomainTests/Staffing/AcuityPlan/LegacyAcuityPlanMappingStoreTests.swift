@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryLegacyAcuityPlanMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.LegacyAcuityPlanMappingStore = Staffing.newMemoryLegacyAcuityPlanMappingStore()
        let item = Staffing.newLegacyAcuityPlanMapping("code-927", name: "name-51")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
