@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryBatchedAssessmentEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.BatchedAssessmentEstimateStore = CareManagement.newMemoryBatchedAssessmentEstimateStore()
        let item = CareManagement.newBatchedAssessmentEstimate("code-848", label: "label-821")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
