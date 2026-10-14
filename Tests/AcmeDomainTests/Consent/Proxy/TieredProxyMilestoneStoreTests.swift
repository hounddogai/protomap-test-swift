@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryTieredProxyMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.TieredProxyMilestoneStore = Consent.newMemoryTieredProxyMilestoneStore()
        let item = Consent.newTieredProxyMilestone("code-4", name: "name-289")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
