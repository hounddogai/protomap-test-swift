@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryScheduledCareProtocolThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.ScheduledCareProtocolThresholdStore = ClinicalOps.newMemoryScheduledCareProtocolThresholdStore()
        let item = ClinicalOps.newScheduledCareProtocolThreshold("code-951", name: "name-908")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
