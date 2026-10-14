@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftBaselineStore = Staffing.newMemoryShiftBaselineStore()
        let item = Staffing.newShiftBaseline("code-281", title: "title-101")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
