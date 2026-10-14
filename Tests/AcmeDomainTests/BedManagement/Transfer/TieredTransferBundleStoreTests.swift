@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTieredTransferBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TieredTransferBundleStore = BedManagement.newMemoryTieredTransferBundleStore()
        let item = BedManagement.newTieredTransferBundle("code-746", label: "label-31")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
