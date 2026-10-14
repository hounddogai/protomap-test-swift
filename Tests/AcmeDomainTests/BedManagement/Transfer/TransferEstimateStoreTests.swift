@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferEstimateStore = BedManagement.newMemoryTransferEstimateStore()
        let item = BedManagement.newTransferEstimate("code-564", label: "label-990")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
