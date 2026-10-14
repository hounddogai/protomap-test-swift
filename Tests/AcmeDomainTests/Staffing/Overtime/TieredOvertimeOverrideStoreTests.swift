@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryTieredOvertimeOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.TieredOvertimeOverrideStore = Staffing.newMemoryTieredOvertimeOverrideStore()
        let item = Staffing.newTieredOvertimeOverride("code-982", name: "name-735")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
