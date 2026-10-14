@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimeCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimeCycleStore = Staffing.newMemoryOvertimeCycleStore()
        let item = Staffing.newOvertimeCycle("code-549", label: "label-80")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
