@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryScheduledIsolationSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ScheduledIsolationSegmentStore = BedManagement.newMemoryScheduledIsolationSegmentStore()
        let item = BedManagement.newScheduledIsolationSegment("code-22", name: "name-78")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
