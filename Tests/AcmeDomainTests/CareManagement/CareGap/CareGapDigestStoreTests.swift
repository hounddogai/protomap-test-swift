@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapDigestStore = CareManagement.newMemoryCareGapDigestStore()
        let item = CareManagement.newCareGapDigest("code-869", name: "name-848")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
