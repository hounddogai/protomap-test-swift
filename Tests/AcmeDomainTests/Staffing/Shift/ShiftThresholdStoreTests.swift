@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftThresholdStore = Staffing.newMemoryShiftThresholdStore()
        let item = Staffing.newShiftThreshold("code-288", name: "name-108")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
