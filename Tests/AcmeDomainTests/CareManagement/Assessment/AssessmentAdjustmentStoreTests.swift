@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentAdjustmentStore = CareManagement.newMemoryAssessmentAdjustmentStore()
        let item = CareManagement.newAssessmentAdjustment("code-631", label: "label-638")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
