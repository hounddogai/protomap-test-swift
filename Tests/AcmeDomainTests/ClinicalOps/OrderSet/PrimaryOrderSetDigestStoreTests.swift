@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPrimaryOrderSetDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PrimaryOrderSetDigestStore = ClinicalOps.newMemoryPrimaryOrderSetDigestStore()
        let item = ClinicalOps.newPrimaryOrderSetDigest("code-118", title: "title-984")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
