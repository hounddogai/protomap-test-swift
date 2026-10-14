@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCareProtocolMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CareProtocolMappingStore = ClinicalOps.newMemoryCareProtocolMappingStore()
        let item = ClinicalOps.newCareProtocolMapping("code-974", title: "title-193")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
