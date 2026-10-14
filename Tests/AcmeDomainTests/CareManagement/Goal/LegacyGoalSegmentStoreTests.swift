@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLegacyGoalSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LegacyGoalSegmentStore = CareManagement.newMemoryLegacyGoalSegmentStore()
        let item = CareManagement.newLegacyGoalSegment("code-389", label: "label-715")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
