@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentPreferenceStore = CareManagement.newMemoryAssessmentPreferenceStore()
        let item = CareManagement.newAssessmentPreference("code-345", title: "title-318")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
