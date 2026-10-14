@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultMilestoneStore = Labs.newMemoryResultMilestoneStore()
        let item = Labs.newResultMilestone("code-603", name: "name-319")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
