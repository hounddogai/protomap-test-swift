@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTieredTaskTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TieredTaskTargetStore = ClinicalOps.newMemoryTieredTaskTargetStore()
        let item = ClinicalOps.newTieredTaskTarget("code-859", name: "name-596")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
