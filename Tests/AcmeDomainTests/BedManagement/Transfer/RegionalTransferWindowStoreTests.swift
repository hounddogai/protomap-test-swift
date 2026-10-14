@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryRegionalTransferWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.RegionalTransferWindowStore = BedManagement.newMemoryRegionalTransferWindowStore()
        let item = BedManagement.newRegionalTransferWindow("code-191", title: "title-890")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
