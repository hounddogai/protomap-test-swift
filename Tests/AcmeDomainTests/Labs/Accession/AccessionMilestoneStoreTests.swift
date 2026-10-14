@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionMilestoneStore = Labs.newMemoryAccessionMilestoneStore()
        let item = Labs.newAccessionMilestone("code-7", name: "name-844")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
