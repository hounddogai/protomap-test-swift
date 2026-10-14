@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRegionalOvertimeSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RegionalOvertimeSegmentStore = Staffing.newMemoryRegionalOvertimeSegmentStore()
        let item = Staffing.newRegionalOvertimeSegment("code-429", label: "label-820")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
