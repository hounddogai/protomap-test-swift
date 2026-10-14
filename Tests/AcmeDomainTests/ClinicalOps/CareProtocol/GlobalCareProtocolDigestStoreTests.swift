@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalCareProtocolDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalCareProtocolDigestStore = ClinicalOps.newMemoryGlobalCareProtocolDigestStore()
        let item = ClinicalOps.newGlobalCareProtocolDigest("code-270", title: "title-700")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
