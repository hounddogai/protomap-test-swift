@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRollingCareProtocolProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RollingCareProtocolProfileStore = ClinicalOps.newMemoryRollingCareProtocolProfileStore()
        let item = ClinicalOps.newRollingCareProtocolProfile("code-782", title: "title-989")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
