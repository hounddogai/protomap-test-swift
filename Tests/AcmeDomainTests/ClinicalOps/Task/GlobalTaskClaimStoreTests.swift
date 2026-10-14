@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalTaskClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalTaskClaimStore = ClinicalOps.newMemoryGlobalTaskClaimStore()
        let item = ClinicalOps.newGlobalTaskClaim("code-674", label: "label-642")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
