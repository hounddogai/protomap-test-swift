@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryScheduledCareProtocolDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.ScheduledCareProtocolDigestStore = ClinicalOps.newMemoryScheduledCareProtocolDigestStore()
        let item = ClinicalOps.newScheduledCareProtocolDigest("code-963", name: "name-342")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
