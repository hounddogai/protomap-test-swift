@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptiveReferenceRangeMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptiveReferenceRangeMilestoneStore = Labs.newMemoryAdaptiveReferenceRangeMilestoneStore()
        let item = Labs.newAdaptiveReferenceRangeMilestone("code-507", title: "title-932")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
