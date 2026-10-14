@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryScheduledCleaningThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ScheduledCleaningThresholdStore = BedManagement.newMemoryScheduledCleaningThresholdStore()
        let item = BedManagement.newScheduledCleaningThreshold("code-276", name: "name-557")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
