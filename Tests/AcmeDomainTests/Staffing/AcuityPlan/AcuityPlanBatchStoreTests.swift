@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanBatchStore = Staffing.newMemoryAcuityPlanBatchStore()
        let item = Staffing.newAcuityPlanBatch("code-106", name: "name-211")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
