@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryPrimaryBedBoardPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.PrimaryBedBoardPlanStore = BedManagement.newMemoryPrimaryBedBoardPlanStore()
        let item = BedManagement.newPrimaryBedBoardPlan("code-628", name: "name-689")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
