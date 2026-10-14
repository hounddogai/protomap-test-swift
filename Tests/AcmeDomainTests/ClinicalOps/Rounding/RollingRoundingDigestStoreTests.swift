@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRollingRoundingDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RollingRoundingDigestStore = ClinicalOps.newMemoryRollingRoundingDigestStore()
        let item = ClinicalOps.newRollingRoundingDigest("code-718", name: "name-943")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
