@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryPendingCleaningPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.PendingCleaningPreferenceStore = BedManagement.newMemoryPendingCleaningPreferenceStore()
        let item = BedManagement.newPendingCleaningPreference("code-285", label: "label-373")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
