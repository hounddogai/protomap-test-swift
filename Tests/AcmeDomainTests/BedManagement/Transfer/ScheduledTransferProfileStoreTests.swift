@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryScheduledTransferProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ScheduledTransferProfileStore = BedManagement.newMemoryScheduledTransferProfileStore()
        let item = BedManagement.newScheduledTransferProfile("code-974", label: "label-108")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
