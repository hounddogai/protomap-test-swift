@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCappedShiftTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CappedShiftTierStore = Staffing.newMemoryCappedShiftTierStore()
        let item = Staffing.newCappedShiftTier("code-891", label: "label-446")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
