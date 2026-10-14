@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryScheduledCleaningQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ScheduledCleaningQuotaStore = BedManagement.newMemoryScheduledCleaningQuotaStore()
        let item = BedManagement.newScheduledCleaningQuota("code-751", name: "name-72")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
