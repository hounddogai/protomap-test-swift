@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryStrictCareProtocolTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.StrictCareProtocolTargetStore = ClinicalOps.newMemoryStrictCareProtocolTargetStore()
        let item = ClinicalOps.newStrictCareProtocolTarget("code-714", label: "label-925")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
