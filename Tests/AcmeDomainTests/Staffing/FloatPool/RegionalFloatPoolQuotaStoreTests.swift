@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRegionalFloatPoolQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RegionalFloatPoolQuotaStore = Staffing.newMemoryRegionalFloatPoolQuotaStore()
        let item = Staffing.newRegionalFloatPoolQuota("code-201", title: "title-749")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
