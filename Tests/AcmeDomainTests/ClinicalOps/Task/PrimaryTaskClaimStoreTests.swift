@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPrimaryTaskClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PrimaryTaskClaimStore = ClinicalOps.newMemoryPrimaryTaskClaimStore()
        let item = ClinicalOps.newPrimaryTaskClaim("code-417", label: "label-517")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
