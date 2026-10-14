@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffBaselineStore = ClinicalOps.newMemoryHandoffBaselineStore()
        let item = ClinicalOps.newHandoffBaseline("code-156", title: "title-144")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
