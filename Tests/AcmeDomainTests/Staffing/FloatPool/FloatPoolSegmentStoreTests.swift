@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolSegmentStore = Staffing.newMemoryFloatPoolSegmentStore()
        let item = Staffing.newFloatPoolSegment("code-739", title: "title-46")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
