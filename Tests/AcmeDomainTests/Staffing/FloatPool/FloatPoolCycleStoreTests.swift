@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolCycleStore = Staffing.newMemoryFloatPoolCycleStore()
        let item = Staffing.newFloatPoolCycle("code-505", name: "name-408")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
