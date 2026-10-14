@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRegionalFloatPoolOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RegionalFloatPoolOverrideStore = Staffing.newMemoryRegionalFloatPoolOverrideStore()
        let item = Staffing.newRegionalFloatPoolOverride("code-321", title: "title-775")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
