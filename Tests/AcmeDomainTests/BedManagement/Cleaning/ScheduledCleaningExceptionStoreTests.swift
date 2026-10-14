@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryScheduledCleaningExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ScheduledCleaningExceptionStore = BedManagement.newMemoryScheduledCleaningExceptionStore()
        let item = BedManagement.newScheduledCleaningException("code-35", name: "name-111")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
