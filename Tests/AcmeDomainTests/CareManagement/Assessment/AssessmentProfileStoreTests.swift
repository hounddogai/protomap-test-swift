@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentProfileStore = CareManagement.newMemoryAssessmentProfileStore()
        let item = CareManagement.newAssessmentProfile("code-184", name: "name-734")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
