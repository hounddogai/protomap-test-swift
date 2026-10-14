@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffBundleStore = ClinicalOps.newMemoryHandoffBundleStore()
        let item = ClinicalOps.newHandoffBundle("code-341", title: "title-505")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
