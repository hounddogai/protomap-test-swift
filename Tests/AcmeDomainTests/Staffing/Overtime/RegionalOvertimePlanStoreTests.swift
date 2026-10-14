@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRegionalOvertimePlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RegionalOvertimePlanStore = Staffing.newMemoryRegionalOvertimePlanStore()
        let item = Staffing.newRegionalOvertimePlan("code-893", name: "name-61")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
