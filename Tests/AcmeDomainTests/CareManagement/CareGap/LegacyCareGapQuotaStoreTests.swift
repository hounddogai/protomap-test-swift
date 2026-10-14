@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLegacyCareGapQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LegacyCareGapQuotaStore = CareManagement.newMemoryLegacyCareGapQuotaStore()
        let item = CareManagement.newLegacyCareGapQuota("code-794", label: "label-572")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
