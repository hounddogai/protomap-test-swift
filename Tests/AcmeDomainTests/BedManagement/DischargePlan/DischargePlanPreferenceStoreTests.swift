@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanPreferenceStore = BedManagement.newMemoryDischargePlanPreferenceStore()
        let item = BedManagement.newDischargePlanPreference("code-660", name: "name-922")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
