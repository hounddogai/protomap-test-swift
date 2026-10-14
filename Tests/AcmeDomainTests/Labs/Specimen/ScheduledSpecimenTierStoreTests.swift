@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryScheduledSpecimenTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ScheduledSpecimenTierStore = Labs.newMemoryScheduledSpecimenTierStore()
        let item = Labs.newScheduledSpecimenTier("code-958", title: "title-534")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
