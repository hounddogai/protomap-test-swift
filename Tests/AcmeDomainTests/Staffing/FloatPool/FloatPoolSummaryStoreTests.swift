@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolSummaryStore = Staffing.newMemoryFloatPoolSummaryStore()
        let item = Staffing.newFloatPoolSummary("code-33", title: "title-878")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
