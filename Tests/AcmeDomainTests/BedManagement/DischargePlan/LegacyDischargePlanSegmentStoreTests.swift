@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLegacyDischargePlanSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LegacyDischargePlanSegmentStore = BedManagement.newMemoryLegacyDischargePlanSegmentStore()
        let item = BedManagement.newLegacyDischargePlanSegment("code-844", title: "title-94")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
