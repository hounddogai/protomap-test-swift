@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPrimaryShiftPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PrimaryShiftPreferenceStore = Staffing.newMemoryPrimaryShiftPreferenceStore()
        let item = Staffing.newPrimaryShiftPreference("code-104", title: "title-460")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
