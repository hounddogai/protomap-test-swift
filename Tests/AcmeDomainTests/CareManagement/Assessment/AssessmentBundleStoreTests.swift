@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentBundleStore = CareManagement.newMemoryAssessmentBundleStore()
        let item = CareManagement.newAssessmentBundle("code-669", label: "label-833")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
