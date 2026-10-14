@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryPrimaryDischargePlanSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.PrimaryDischargePlanSummaryStore = BedManagement.newMemoryPrimaryDischargePlanSummaryStore()
        let item = BedManagement.newPrimaryDischargePlanSummary("code-379", title: "title-784")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
