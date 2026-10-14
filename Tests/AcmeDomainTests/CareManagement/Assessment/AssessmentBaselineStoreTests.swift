@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentBaselineStore = CareManagement.newMemoryAssessmentBaselineStore()
        let item = CareManagement.newAssessmentBaseline("code-82", name: "name-208")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
