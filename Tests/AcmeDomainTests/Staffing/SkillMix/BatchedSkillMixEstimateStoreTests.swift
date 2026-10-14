@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryBatchedSkillMixEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.BatchedSkillMixEstimateStore = Staffing.newMemoryBatchedSkillMixEstimateStore()
        let item = Staffing.newBatchedSkillMixEstimate("code-217", title: "title-298")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
