@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierMilestoneStore = Labs.newMemoryCourierMilestoneStore()
        let item = Labs.newCourierMilestone("code-210", label: "label-642")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
