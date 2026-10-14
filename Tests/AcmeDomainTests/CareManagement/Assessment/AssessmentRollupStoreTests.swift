@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentRollupStore = CareManagement.newMemoryAssessmentRollupStore()
        let item = CareManagement.newAssessmentRollup("code-868", label: "label-517")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
