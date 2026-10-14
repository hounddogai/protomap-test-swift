@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanCheckpointStore = Staffing.newMemoryAcuityPlanCheckpointStore()
        let item = Staffing.newAcuityPlanCheckpoint("code-265", name: "name-731")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
