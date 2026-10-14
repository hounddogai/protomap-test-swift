@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimeSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimeSummaryStore = Staffing.newMemoryOvertimeSummaryStore()
        let item = Staffing.newOvertimeSummary("code-148", title: "title-166")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
