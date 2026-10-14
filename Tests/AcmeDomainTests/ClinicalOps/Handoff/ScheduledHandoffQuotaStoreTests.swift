@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryScheduledHandoffQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.ScheduledHandoffQuotaStore = ClinicalOps.newMemoryScheduledHandoffQuotaStore()
        let item = ClinicalOps.newScheduledHandoffQuota("code-512", name: "name-633")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
