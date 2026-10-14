@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffQuotaStore = ClinicalOps.newMemoryHandoffQuotaStore()
        let item = ClinicalOps.newHandoffQuota("code-598", name: "name-814")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
