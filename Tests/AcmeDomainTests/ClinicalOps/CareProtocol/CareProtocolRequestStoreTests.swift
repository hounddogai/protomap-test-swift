@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCareProtocolRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CareProtocolRequestStore = ClinicalOps.newMemoryCareProtocolRequestStore()
        let item = ClinicalOps.newCareProtocolRequest("code-77", name: "name-222")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
