@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryTieredCareGapPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.TieredCareGapPolicyStore = CareManagement.newMemoryTieredCareGapPolicyStore()
        let item = CareManagement.newTieredCareGapPolicy("code-258", name: "name-440")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
