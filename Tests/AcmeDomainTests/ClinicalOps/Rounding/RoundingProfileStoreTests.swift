@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingProfileStore = ClinicalOps.newMemoryRoundingProfileStore()
        let item = ClinicalOps.newRoundingProfile("code-215", name: "name-475")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
