@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryManualCareProtocolRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.ManualCareProtocolRequestStore = ClinicalOps.newMemoryManualCareProtocolRequestStore()
        let item = ClinicalOps.newManualCareProtocolRequest("code-921", name: "name-106")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
