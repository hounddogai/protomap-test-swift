@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRollingOrderSetWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RollingOrderSetWindowStore = ClinicalOps.newMemoryRollingOrderSetWindowStore()
        let item = ClinicalOps.newRollingOrderSetWindow("code-280", name: "name-968")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
