@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCappedCareGapQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CappedCareGapQuotaStore = CareManagement.newMemoryCappedCareGapQuotaStore()
        let item = CareManagement.newCappedCareGapQuota("code-760", label: "label-638")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
