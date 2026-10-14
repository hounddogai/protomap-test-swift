@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTieredHandoffOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TieredHandoffOverrideStore = ClinicalOps.newMemoryTieredHandoffOverrideStore()
        let item = ClinicalOps.newTieredHandoffOverride("code-844", title: "title-447")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
