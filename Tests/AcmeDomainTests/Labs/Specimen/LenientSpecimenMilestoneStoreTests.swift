@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLenientSpecimenMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LenientSpecimenMilestoneStore = Labs.newMemoryLenientSpecimenMilestoneStore()
        let item = Labs.newLenientSpecimenMilestone("code-847", label: "label-609")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
