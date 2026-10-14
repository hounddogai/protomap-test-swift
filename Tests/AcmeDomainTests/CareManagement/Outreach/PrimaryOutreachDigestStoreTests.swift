@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPrimaryOutreachDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PrimaryOutreachDigestStore = CareManagement.newMemoryPrimaryOutreachDigestStore()
        let item = CareManagement.newPrimaryOutreachDigest("code-967", title: "title-167")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
