@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningRequestStore = BedManagement.newMemoryCleaningRequestStore()
        let item = BedManagement.newCleaningRequest("code-422", name: "name-545")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
