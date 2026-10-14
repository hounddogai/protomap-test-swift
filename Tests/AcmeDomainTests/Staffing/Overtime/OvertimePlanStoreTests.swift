@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimePlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimePlanStore = Staffing.newMemoryOvertimePlanStore()
        let item = Staffing.newOvertimePlan("code-138", title: "title-677")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
