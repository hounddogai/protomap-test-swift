@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLenientAssessmentScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LenientAssessmentScoreStore = CareManagement.newMemoryLenientAssessmentScoreStore()
        let item = CareManagement.newLenientAssessmentScore("code-549", name: "name-370")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
