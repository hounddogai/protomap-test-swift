@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemorySeasonalOutreachDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.SeasonalOutreachDigestStore = CareManagement.newMemorySeasonalOutreachDigestStore()
        let item = CareManagement.newSeasonalOutreachDigest("code-404", name: "name-206")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
