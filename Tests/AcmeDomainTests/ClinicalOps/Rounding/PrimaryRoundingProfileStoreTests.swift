@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPrimaryRoundingProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PrimaryRoundingProfileStore = ClinicalOps.newMemoryPrimaryRoundingProfileStore()
        let item = ClinicalOps.newPrimaryRoundingProfile("code-336", title: "title-854")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
