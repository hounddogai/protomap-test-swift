@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskDigestStore = ClinicalOps.newMemoryTaskDigestStore()
        let item = ClinicalOps.newTaskDigest("code-961", title: "title-402")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
