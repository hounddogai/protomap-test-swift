@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingTargetStore = ClinicalOps.newMemoryRoundingTargetStore()
        let item = ClinicalOps.newRoundingTarget("code-218", label: "label-142")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
