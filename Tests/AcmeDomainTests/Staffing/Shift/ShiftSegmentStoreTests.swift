@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftSegmentStore = Staffing.newMemoryShiftSegmentStore()
        let item = Staffing.newShiftSegment("code-969", label: "label-856")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
