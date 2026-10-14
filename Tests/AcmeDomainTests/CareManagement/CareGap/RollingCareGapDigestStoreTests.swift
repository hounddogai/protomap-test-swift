@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRollingCareGapDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RollingCareGapDigestStore = CareManagement.newMemoryRollingCareGapDigestStore()
        let item = CareManagement.newRollingCareGapDigest("code-438", title: "title-974")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
