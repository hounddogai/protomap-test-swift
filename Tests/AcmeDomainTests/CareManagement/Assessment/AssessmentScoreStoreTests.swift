@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentScoreStore = CareManagement.newMemoryAssessmentScoreStore()
        let item = CareManagement.newAssessmentScore("code-590", title: "title-597")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
