@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCareProtocolAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CareProtocolAdjustmentStore = ClinicalOps.newMemoryCareProtocolAdjustmentStore()
        let item = ClinicalOps.newCareProtocolAdjustment("code-393", name: "name-205")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
