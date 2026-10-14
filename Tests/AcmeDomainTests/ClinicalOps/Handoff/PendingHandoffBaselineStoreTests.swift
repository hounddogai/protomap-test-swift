@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPendingHandoffBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PendingHandoffBaselineStore = ClinicalOps.newMemoryPendingHandoffBaselineStore()
        let item = ClinicalOps.newPendingHandoffBaseline("code-381", title: "title-847")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
