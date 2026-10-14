@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryManualIsolationPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ManualIsolationPreferenceStore = BedManagement.newMemoryManualIsolationPreferenceStore()
        let item = BedManagement.newManualIsolationPreference("code-511", name: "name-949")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
