@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryLenientShiftSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.LenientShiftSegmentStore = Staffing.newMemoryLenientShiftSegmentStore()
        let item = Staffing.newLenientShiftSegment("code-340", title: "title-366")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
