@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryRegionalIsolationPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.RegionalIsolationPlanStore = BedManagement.newMemoryRegionalIsolationPlanStore()
        let item = BedManagement.newRegionalIsolationPlan("code-629", title: "title-279")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
