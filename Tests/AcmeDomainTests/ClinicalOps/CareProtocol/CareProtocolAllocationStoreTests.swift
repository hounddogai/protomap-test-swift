@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCareProtocolAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CareProtocolAllocationStore = ClinicalOps.newMemoryCareProtocolAllocationStore()
        let item = ClinicalOps.newCareProtocolAllocation("code-832", name: "name-611")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
