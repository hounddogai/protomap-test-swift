@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryBatchedAssessmentBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.BatchedAssessmentBaselineStore = CareManagement.newMemoryBatchedAssessmentBaselineStore()
        let item = CareManagement.newBatchedAssessmentBaseline("code-905", label: "label-343")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
