@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftVarianceStore = Staffing.newMemoryShiftVarianceStore()
        let item = Staffing.newShiftVariance("code-277", title: "title-928")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
