@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolAdjustmentStore = Staffing.newMemoryFloatPoolAdjustmentStore()
        let item = Staffing.newFloatPoolAdjustment("code-582", label: "label-930")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
