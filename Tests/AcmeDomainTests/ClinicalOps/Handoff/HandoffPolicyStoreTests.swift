@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffPolicyStore = ClinicalOps.newMemoryHandoffPolicyStore()
        let item = ClinicalOps.newHandoffPolicy("code-707", title: "title-694")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
