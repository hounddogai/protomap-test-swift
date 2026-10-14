@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryLenientShiftThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.LenientShiftThresholdStore = Staffing.newMemoryLenientShiftThresholdStore()
        let item = Staffing.newLenientShiftThreshold("code-468", name: "name-972")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
