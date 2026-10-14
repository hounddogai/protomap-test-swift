@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryWeightedTransferGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.WeightedTransferGroupStore = BedManagement.newMemoryWeightedTransferGroupStore()
        let item = BedManagement.newWeightedTransferGroup("code-561", title: "title-330")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
