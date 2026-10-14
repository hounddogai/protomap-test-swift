@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCensusAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CensusAdjustmentStore = BedManagement.newMemoryCensusAdjustmentStore()
        let item = BedManagement.newCensusAdjustment("code-157", title: "title-118")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
