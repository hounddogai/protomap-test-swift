@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryStrictShiftThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.StrictShiftThresholdStore = Staffing.newMemoryStrictShiftThresholdStore()
        let item = Staffing.newStrictShiftThreshold("code-504", label: "label-534")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
