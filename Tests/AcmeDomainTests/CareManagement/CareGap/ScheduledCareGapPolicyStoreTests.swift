@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryScheduledCareGapPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ScheduledCareGapPolicyStore = CareManagement.newMemoryScheduledCareGapPolicyStore()
        let item = CareManagement.newScheduledCareGapPolicy("code-881", name: "name-452")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
