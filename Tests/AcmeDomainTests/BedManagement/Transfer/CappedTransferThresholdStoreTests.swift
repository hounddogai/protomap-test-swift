@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCappedTransferThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CappedTransferThresholdStore = BedManagement.newMemoryCappedTransferThresholdStore()
        let item = BedManagement.newCappedTransferThreshold("code-357", title: "title-731")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
