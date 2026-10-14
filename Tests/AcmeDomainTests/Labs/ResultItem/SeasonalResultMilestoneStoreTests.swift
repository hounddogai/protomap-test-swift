@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySeasonalResultMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SeasonalResultMilestoneStore = Labs.newMemorySeasonalResultMilestoneStore()
        let item = Labs.newSeasonalResultMilestone("code-261", name: "name-164")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
