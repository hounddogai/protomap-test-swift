@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryManualCareGapSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ManualCareGapSummaryStore = CareManagement.newMemoryManualCareGapSummaryStore()
        let item = CareManagement.newManualCareGapSummary("code-294", name: "name-418")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
