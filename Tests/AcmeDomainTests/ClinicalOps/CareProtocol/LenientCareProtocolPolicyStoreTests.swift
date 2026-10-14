@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLenientCareProtocolPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LenientCareProtocolPolicyStore = ClinicalOps.newMemoryLenientCareProtocolPolicyStore()
        let item = ClinicalOps.newLenientCareProtocolPolicy("code-321", title: "title-615")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
