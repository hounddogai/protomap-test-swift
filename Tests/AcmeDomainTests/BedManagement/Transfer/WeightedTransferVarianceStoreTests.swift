@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryWeightedTransferVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.WeightedTransferVarianceStore = BedManagement.newMemoryWeightedTransferVarianceStore()
        let item = BedManagement.newWeightedTransferVariance("code-590", name: "name-252")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
