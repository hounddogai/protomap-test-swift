@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryGlobalIsolationRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.GlobalIsolationRequestStore = BedManagement.newMemoryGlobalIsolationRequestStore()
        let item = BedManagement.newGlobalIsolationRequest("code-914", title: "title-863")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
