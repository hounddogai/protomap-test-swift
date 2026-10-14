@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPrimaryAcuityPlanTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PrimaryAcuityPlanTargetStore = Staffing.newMemoryPrimaryAcuityPlanTargetStore()
        let item = Staffing.newPrimaryAcuityPlanTarget("code-593", title: "title-363")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
