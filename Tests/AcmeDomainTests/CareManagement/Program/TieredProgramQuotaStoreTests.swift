@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryTieredProgramQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.TieredProgramQuotaStore = CareManagement.newMemoryTieredProgramQuotaStore()
        let item = CareManagement.newTieredProgramQuota("code-471", name: "name-767")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
