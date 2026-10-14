@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAdaptiveHandoffDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AdaptiveHandoffDigestStore = ClinicalOps.newMemoryAdaptiveHandoffDigestStore()
        let item = ClinicalOps.newAdaptiveHandoffDigest("code-336", label: "label-356")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
