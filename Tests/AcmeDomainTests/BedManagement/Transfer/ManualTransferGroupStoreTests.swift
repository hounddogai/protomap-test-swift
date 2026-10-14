@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryManualTransferGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ManualTransferGroupStore = BedManagement.newMemoryManualTransferGroupStore()
        let item = BedManagement.newManualTransferGroup("code-291", label: "label-489")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
