@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryDefaultCareProtocolSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.DefaultCareProtocolSummaryStore = ClinicalOps.newMemoryDefaultCareProtocolSummaryStore()
        let item = ClinicalOps.newDefaultCareProtocolSummary("code-671", name: "name-184")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
