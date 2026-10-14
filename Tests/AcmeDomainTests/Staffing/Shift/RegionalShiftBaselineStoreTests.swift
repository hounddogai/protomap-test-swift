@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRegionalShiftBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RegionalShiftBaselineStore = Staffing.newMemoryRegionalShiftBaselineStore()
        let item = Staffing.newRegionalShiftBaseline("code-44", name: "name-733")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
