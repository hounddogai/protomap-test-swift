@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningProfileStore = BedManagement.newMemoryCleaningProfileStore()
        let item = BedManagement.newCleaningProfile("code-143", name: "name-971")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
