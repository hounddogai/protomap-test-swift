@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCappedAssessmentBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CappedAssessmentBaselineStore = CareManagement.newMemoryCappedAssessmentBaselineStore()
        let item = CareManagement.newCappedAssessmentBaseline("code-497", label: "label-123")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
