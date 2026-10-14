@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapQuotaStore = CareManagement.newMemoryCareGapQuotaStore()
        let item = CareManagement.newCareGapQuota("code-519", title: "title-10")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
