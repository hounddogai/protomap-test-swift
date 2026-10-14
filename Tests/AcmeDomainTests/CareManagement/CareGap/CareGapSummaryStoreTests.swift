@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapSummaryStore = CareManagement.newMemoryCareGapSummaryStore()
        let item = CareManagement.newCareGapSummary("code-60", title: "title-324")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
