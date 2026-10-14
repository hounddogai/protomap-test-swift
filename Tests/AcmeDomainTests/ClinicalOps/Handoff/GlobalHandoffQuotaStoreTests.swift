@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalHandoffQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalHandoffQuotaStore = ClinicalOps.newMemoryGlobalHandoffQuotaStore()
        let item = ClinicalOps.newGlobalHandoffQuota("code-837", title: "title-334")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
