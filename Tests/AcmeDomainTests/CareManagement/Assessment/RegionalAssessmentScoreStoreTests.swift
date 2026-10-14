@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRegionalAssessmentScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RegionalAssessmentScoreStore = CareManagement.newMemoryRegionalAssessmentScoreStore()
        let item = CareManagement.newRegionalAssessmentScore("code-578", name: "name-939")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
