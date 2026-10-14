@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAdaptiveAssessmentAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AdaptiveAssessmentAllocationStore = CareManagement.newMemoryAdaptiveAssessmentAllocationStore()
        let item = CareManagement.newAdaptiveAssessmentAllocation("code-696", name: "name-238")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
