@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentTemplateStore = CareManagement.newMemoryAssessmentTemplateStore()
        let item = CareManagement.newAssessmentTemplate("code-438", name: "name-169")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
