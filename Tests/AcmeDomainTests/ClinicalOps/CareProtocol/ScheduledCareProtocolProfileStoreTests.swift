@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryScheduledCareProtocolProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.ScheduledCareProtocolProfileStore = ClinicalOps.newMemoryScheduledCareProtocolProfileStore()
        let item = ClinicalOps.newScheduledCareProtocolProfile("code-570", name: "name-807")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
