@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCareProtocolOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CareProtocolOverrideStore = ClinicalOps.newMemoryCareProtocolOverrideStore()
        let item = ClinicalOps.newCareProtocolOverride("code-631", title: "title-144")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
