@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingBundleStore = ClinicalOps.newMemoryRoundingBundleStore()
        let item = ClinicalOps.newRoundingBundle("code-494", name: "name-278")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
