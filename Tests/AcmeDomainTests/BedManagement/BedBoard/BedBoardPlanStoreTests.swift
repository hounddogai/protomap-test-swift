@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardPlanStore = BedManagement.newMemoryBedBoardPlanStore()
        let item = BedManagement.newBedBoardPlan("code-939", label: "label-457")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
