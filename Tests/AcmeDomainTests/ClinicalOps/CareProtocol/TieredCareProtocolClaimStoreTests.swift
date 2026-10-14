@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTieredCareProtocolClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TieredCareProtocolClaimStore = ClinicalOps.newMemoryTieredCareProtocolClaimStore()
        let item = ClinicalOps.newTieredCareProtocolClaim("code-865", label: "label-345")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
